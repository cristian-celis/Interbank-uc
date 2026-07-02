"""Repositorio del lado app de clientes — consultas sobre bd_core_mobile."""
import uuid
from datetime import datetime, timezone
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.models.mdl_clientes import Cliente
from app.models.mdl_cliente_mobile import (
    UsuarioCliente, CrCuentaAhorro, CrCredito, CrCronogramaPago,
    CrMovimiento, Tarjeta, OperacionCliente, Notificacion,
)
from app.core.credit_policy import french_installment, validate_credit_terms


def get_usuario_by_username(db: Session, username: str) -> UsuarioCliente | None:
    return db.query(UsuarioCliente).filter(
        UsuarioCliente.username == username
    ).first()


def get_cliente(db: Session, cliente_id: str) -> Cliente | None:
    return db.query(Cliente).filter(Cliente.id == cliente_id).first()


def cuentas_ahorro(db: Session, cliente_id: str) -> list[CrCuentaAhorro]:
    return db.query(CrCuentaAhorro).filter(
        CrCuentaAhorro.cliente_id == cliente_id
    ).order_by(CrCuentaAhorro.cod_cuenta_ahorro.asc()).all()


def creditos(db: Session, cliente_id: str) -> list[CrCredito]:
    return db.query(CrCredito).filter(
        CrCredito.cliente_id == cliente_id
    ).order_by(CrCredito.fecha_desembolso.desc().nullslast()).all()


def cronograma(db: Session, cod_cuenta_credito: str) -> list[CrCronogramaPago]:
    return db.query(CrCronogramaPago).filter(
        CrCronogramaPago.cod_cuenta_credito == cod_cuenta_credito
    ).order_by(CrCronogramaPago.nro_cuota.asc()).all()


def movimientos(db: Session, cliente_id: str, limit: int = 20) -> list[CrMovimiento]:
    return db.query(CrMovimiento).filter(
        CrMovimiento.cliente_id == cliente_id
    ).order_by(CrMovimiento.fecha_operacion.desc()).limit(limit).all()


def tarjetas(db: Session, cliente_id: str) -> list[Tarjeta]:
    return db.query(Tarjeta).filter(
        Tarjeta.cliente_id == cliente_id
    ).order_by(Tarjeta.created_at.asc()).all()


def notificaciones(db: Session, cliente_id: str, limit: int = 30) -> list[Notificacion]:
    return db.query(Notificacion).filter(
        Notificacion.destinatario_tipo == "cliente",
        Notificacion.cliente_id == cliente_id,
    ).order_by(Notificacion.created_at.desc()).limit(limit).all()


def crear_operacion(db: Session, cliente_id: str, data: dict) -> OperacionCliente:
    monto = float(data.get("monto") or 0)
    if monto <= 0:
        raise ValueError("El monto debe ser mayor a cero")

    origen = db.query(CrCuentaAhorro).filter(
        CrCuentaAhorro.cliente_id == cliente_id,
        CrCuentaAhorro.cod_cuenta_ahorro == data.get("cod_cuenta_origen"),
    ).with_for_update().first()
    if not origen:
        raise ValueError("Cuenta origen no encontrada")
    if float(origen.saldo_capital or 0) < monto:
        raise ValueError("Saldo insuficiente")

    destino_codigo = data.get("cod_cuenta_destino")
    tipo = data.get("tipo")
    destino = None
    credito = None
    if tipo == "transferencia":
        destino = db.query(CrCuentaAhorro).filter(
            CrCuentaAhorro.cod_cuenta_ahorro == destino_codigo
        ).with_for_update().first()
        if not destino:
            raise ValueError("Cuenta destino no encontrada")
    elif tipo == "pago_cuota":
        credito = db.query(CrCredito).filter(
            CrCredito.cliente_id == cliente_id,
            CrCredito.cod_cuenta_credito == destino_codigo,
        ).with_for_update().first()
        if not credito:
            raise ValueError("Credito destino no encontrado")

    op = OperacionCliente(
        cliente_id=cliente_id,
        cod_cuenta_origen=origen.cod_cuenta_ahorro,
        cod_cuenta_destino=destino_codigo,
        tipo=tipo,
        monto=monto,
        moneda=data.get("moneda", "PEN"),
        estado="confirmada",
        cod_operacion_core="APP-" + uuid.uuid4().hex[:12].upper(),
    )
    origen.saldo_capital = float(origen.saldo_capital or 0) - monto
    if destino:
        destino.saldo_capital = float(destino.saldo_capital or 0) + monto
    if credito:
        credito.saldo_capital = max(0, float(credito.saldo_capital or 0) - monto)
        credito.saldo_total = max(0, float(credito.saldo_total or 0) - monto)

    db.add(op)
    db.add(CrMovimiento(
        cod_operacion=op.cod_operacion_core,
        cliente_id=cliente_id,
        cod_cuenta=origen.cod_cuenta_ahorro,
        tipo="DEB",
        concepto="Transferencia" if tipo == "transferencia" else "Pago de cuota",
        canal="APP",
        monto=monto,
        moneda=data.get("moneda", "PEN"),
        fecha_operacion=datetime.now(timezone.utc),
    ))
    if destino:
        db.add(CrMovimiento(
            cod_operacion="CRE-" + uuid.uuid4().hex[:12].upper(),
            cliente_id=destino.cliente_id,
            cod_cuenta=destino.cod_cuenta_ahorro,
            tipo="CRE",
            concepto="Transferencia recibida",
            canal="APP",
            monto=monto,
            moneda=data.get("moneda", "PEN"),
            fecha_operacion=datetime.now(timezone.utc),
        ))
    db.commit()
    db.refresh(op)
    return op


def crear_solicitud_cliente(db: Session, cliente_id: str, data: dict) -> dict:
    asignado = db.execute(text("""
        SELECT a.id, a.agencia_id
        FROM asesores a
        WHERE a.activo = TRUE
          AND a.codigo_empleado = '0001'
        LIMIT 1
    """)).mappings().first()
    if not asignado:
        raise ValueError("No hay vendedores disponibles")

    solicitud_id = str(uuid.uuid4())
    expediente = "EXP-" + solicitud_id.replace("-", "")[:8].upper()
    _, tea = validate_credit_terms(
        amount=float(data["monto_solicitado"]),
        term_months=int(data["plazo_meses"]),
        tea=None,
        destino_credito=data.get("destino_credito"),
        tipo_negocio=data.get("tipo_negocio"),
    )
    cuota = french_installment(
        float(data["monto_solicitado"]),
        int(data["plazo_meses"]),
        tea,
    )
    db.execute(text("""
        INSERT INTO solicitudes_credito (
            id, numero_expediente, asesor_id, cliente_id, agencia_id, canal,
            tipo_negocio, nombre_negocio, ingresos_estimados, monto_solicitado,
            plazo_meses, moneda, tipo_cuota, garantia, destino_credito,
            cuota_estimada, tea_referencial, estado
        ) VALUES (
            :id, :exp, :asesor, :cliente, :agencia, 'cliente',
            :tipo_negocio, :nombre_negocio, :ingresos, :monto,
            :plazo, 'PEN', 'mensual', 'sin_garantia', :destino,
            :cuota, :tea, 'borrador'
        )
    """), {
        "id": solicitud_id, "exp": expediente, "asesor": asignado["id"],
        "cliente": cliente_id, "agencia": asignado["agencia_id"],
        "tipo_negocio": data.get("tipo_negocio"),
        "nombre_negocio": data.get("nombre_negocio"),
        "ingresos": data.get("ingresos_estimados"),
        "monto": data["monto_solicitado"], "plazo": data["plazo_meses"],
        "destino": data["destino_credito"], "cuota": cuota, "tea": tea,
    })
    db.add(Notificacion(
        destinatario_tipo="asesor",
        asesor_id=asignado["id"],
        titulo="Nueva solicitud asignada",
        cuerpo=f"El cliente inicio la solicitud {expediente}.",
        tipo="solicitud_asignada",
        data_json={"solicitud_id": solicitud_id},
    ))
    db.commit()
    return get_solicitud_cliente(db, cliente_id, solicitud_id)


def get_solicitud_cliente(db: Session, cliente_id: str, solicitud_id: str) -> dict | None:
    return db.execute(text("""
        SELECT s.id, s.numero_expediente, s.monto_solicitado, s.monto_aprobado,
               s.plazo_meses, s.destino_credito, s.estado, s.motivo_rechazo,
               s.created_at, a.nombres || ' ' || a.apellidos AS asesor_nombre
        FROM solicitudes_credito s
        JOIN asesores a ON a.id = s.asesor_id
        WHERE s.id = :id AND s.cliente_id = :cliente
    """), {"id": solicitud_id, "cliente": cliente_id}).mappings().first()


def solicitudes_cliente(db: Session, cliente_id: str) -> list[dict]:
    rows = db.execute(text("""
        SELECT s.id, s.numero_expediente, s.monto_solicitado, s.monto_aprobado,
               s.plazo_meses, s.destino_credito, s.estado, s.motivo_rechazo,
               s.created_at, a.nombres || ' ' || a.apellidos AS asesor_nombre
        FROM solicitudes_credito s
        JOIN asesores a ON a.id = s.asesor_id
        WHERE s.cliente_id = :cliente
        ORDER BY s.created_at DESC
    """), {"cliente": cliente_id}).mappings().all()
    return [dict(row) for row in rows]
