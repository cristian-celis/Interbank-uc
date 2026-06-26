import math
import uuid
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session


def listar_solicitudes(db: Session, estado: str | None = None) -> list[dict]:
    rows = db.execute(text("""
        SELECT s.id, s.numero_expediente, s.canal, s.estado, s.monto_solicitado,
               s.monto_aprobado, s.plazo_meses, s.destino_credito,
               s.ingresos_estimados, s.gastos_mensuales, s.firma_cliente_base64,
               s.lat_captura, s.lng_captura, s.created_at,
               c.numero_documento, c.nombres || ' ' || c.apellidos AS cliente_nombre,
               a.nombres || ' ' || a.apellidos AS asesor_nombre
        FROM solicitudes_credito s
        JOIN clientes c ON c.id = s.cliente_id
        JOIN asesores a ON a.id = s.asesor_id
        WHERE (:estado IS NULL OR s.estado = :estado)
        ORDER BY s.created_at DESC
    """), {"estado": estado}).mappings().all()
    return [dict(row) for row in rows]


def decidir(
    db: Session,
    solicitud_id: str,
    decisor_id: str,
    decision: str,
    monto_aprobado: float | None,
    motivo: str | None,
) -> dict:
    solicitud = db.execute(text("""
        SELECT * FROM solicitudes_credito WHERE id = :id FOR UPDATE
    """), {"id": solicitud_id}).mappings().first()
    if not solicitud:
        raise ValueError("Solicitud no encontrada")
    if decision not in {"aprobado", "rechazado", "condicionado"}:
        raise ValueError("Decision no valida")
    if solicitud["estado"] not in {"enviado", "recibido_comite", "en_evaluacion", "condicionado"}:
        raise ValueError(f"No se puede decidir una solicitud en estado {solicitud['estado']}")
    if decision == "aprobado" and (not monto_aprobado or monto_aprobado <= 0):
        raise ValueError("El monto aprobado es obligatorio")
    if decision == "rechazado" and not motivo:
        raise ValueError("El motivo de rechazo es obligatorio")

    db.execute(text("""
        UPDATE solicitudes_credito
        SET estado = :decision,
            monto_aprobado = :monto,
            motivo_rechazo = CASE WHEN :decision = 'rechazado' THEN :motivo ELSE NULL END,
            condicion_adicional = CASE WHEN :decision = 'condicionado' THEN :motivo ELSE NULL END,
            analista_asignado = (SELECT nombres || ' ' || apellidos FROM asesores WHERE id=:decisor),
            updated_at = now()
        WHERE id = :id
    """), {
        "decision": decision, "monto": monto_aprobado, "motivo": motivo,
        "decisor": decisor_id, "id": solicitud_id,
    })
    db.execute(text("""
        INSERT INTO solicitudes_decisiones
            (solicitud_id, asesor_decisor_id, decision, monto_aprobado, motivo)
        VALUES (:solicitud, :decisor, :decision, :monto, :motivo)
    """), {
        "solicitud": solicitud_id, "decisor": decisor_id,
        "decision": decision, "monto": monto_aprobado, "motivo": motivo,
    })

    if decision == "aprobado":
        _desembolsar(db, solicitud, float(monto_aprobado))
    else:
        _notificar(
            db, solicitud["cliente_id"], solicitud["asesor_id"],
            "Solicitud rechazada" if decision == "rechazado" else "Solicitud condicionada",
            motivo or "Revisa las condiciones de tu solicitud.", decision, solicitud_id,
        )
    db.commit()
    return {"id": solicitud_id, "estado": "desembolsado" if decision == "aprobado" else decision}


def _desembolsar(db: Session, solicitud: dict, monto: float) -> None:
    plazo = int(solicitud["plazo_meses"] or 12)
    tea = float(solicitud["tea_referencial"] or 32)
    monthly_rate = (1 + tea / 100) ** (1 / 12) - 1
    cuota = monto * monthly_rate / (1 - (1 + monthly_rate) ** -plazo)
    codigo = "CRED-MOB-" + uuid.uuid4().hex[:10].upper()
    db.execute(text("""
        INSERT INTO cr_creditos (
            cod_cuenta_credito, cliente_id, producto, monto_desembolsado,
            saldo_capital, saldo_total, dias_mora, calificacion_interna,
            estado, fecha_desembolso, tea, cuotas_total, cuotas_pagadas
        ) VALUES (
            :codigo, :cliente, 'Prestamo movil', :monto,
            :monto, :total, 0, 'normal', 'vigente', current_date,
            :tea, :plazo, 0
        )
    """), {
        "codigo": codigo, "cliente": solicitud["cliente_id"], "monto": monto,
        "total": round(cuota * plazo, 2), "tea": tea, "plazo": plazo,
    })
    saldo = monto
    for nro in range(1, plazo + 1):
        interes = saldo * monthly_rate
        capital = min(saldo, cuota - interes)
        saldo = max(0, saldo - capital)
        db.execute(text("""
            INSERT INTO cr_cronograma_pagos (
                cod_cuenta_credito, nro_cuota, fecha_vencimiento, monto_cuota,
                monto_capital, monto_interes, saldo, estado_cuota
            ) VALUES (:codigo, :nro, :fecha, :cuota, :capital, :interes, :saldo, 'pendiente')
        """), {
            "codigo": codigo, "nro": nro,
            "fecha": date.today() + timedelta(days=30 * nro),
            "cuota": round(cuota, 2), "capital": round(capital, 2),
            "interes": round(interes, 2), "saldo": round(saldo, 2),
        })

    cuenta = db.execute(text("""
        SELECT cod_cuenta_ahorro FROM cr_cuentas_ahorro
        WHERE cliente_id=:cliente AND estado='activa'
        ORDER BY cod_cuenta_ahorro LIMIT 1
    """), {"cliente": solicitud["cliente_id"]}).first()
    if cuenta:
        db.execute(text("""
            UPDATE cr_cuentas_ahorro
            SET saldo_capital = saldo_capital + :monto, sync_at=now()
            WHERE cod_cuenta_ahorro=:cuenta
        """), {"monto": monto, "cuenta": cuenta[0]})
        db.execute(text("""
            INSERT INTO cr_movimientos (
                cod_operacion, cliente_id, cod_cuenta, tipo, concepto, canal,
                monto, moneda, fecha_operacion
            ) VALUES (:op, :cliente, :cuenta, 'CRE', 'Desembolso de prestamo', 'WEB',
                      :monto, 'PEN', now())
        """), {
            "op": "DES-" + uuid.uuid4().hex[:12].upper(),
            "cliente": solicitud["cliente_id"], "cuenta": cuenta[0], "monto": monto,
        })
    db.execute(text("""
        UPDATE solicitudes_credito SET estado='desembolsado', updated_at=now()
        WHERE id=:id
    """), {"id": solicitud["id"]})
    _notificar(
        db, solicitud["cliente_id"], solicitud["asesor_id"],
        "Prestamo aprobado y desembolsado",
        f"Se desembolsaron S/ {monto:,.2f}.", "desembolsado", str(solicitud["id"]),
    )


def _notificar(
    db: Session, cliente_id, asesor_id, titulo: str, cuerpo: str,
    tipo: str, solicitud_id: str,
) -> None:
    for destinatario, cid, aid in [
        ("cliente", cliente_id, None),
        ("asesor", None, asesor_id),
    ]:
        db.execute(text("""
            INSERT INTO notificaciones (
                destinatario_tipo, cliente_id, asesor_id, titulo, cuerpo, tipo, data_json
            ) VALUES (:tipo_dest, :cliente, :asesor, :titulo, :cuerpo, :tipo,
                      jsonb_build_object('solicitud_id', :solicitud))
        """), {
            "tipo_dest": destinatario, "cliente": cid, "asesor": aid,
            "titulo": titulo, "cuerpo": cuerpo, "tipo": tipo, "solicitud": solicitud_id,
        })
