"""Reinicia el happy path usado para grabar el video."""
from sqlalchemy import text

from app.core.cfg_database import SessionLocal


def main() -> None:
    db = SessionLocal()
    try:
        cliente = db.execute(
            text("SELECT id FROM clientes WHERE numero_documento='40000001'")
        ).scalar_one()
        solicitudes = db.execute(
            text(
                "SELECT id FROM solicitudes_credito "
                "WHERE cliente_id=:cliente AND canal='cliente'"
            ),
            {"cliente": cliente},
        ).scalars().all()

        if solicitudes:
            db.execute(
                text("DELETE FROM consultas_buro WHERE solicitud_id = ANY(:ids)"),
                {"ids": solicitudes},
            )
            db.execute(
                text("DELETE FROM sync_outbox WHERE entidad_id = ANY(:ids)"),
                {"ids": solicitudes},
            )
            db.execute(
                text("DELETE FROM solicitudes_credito WHERE id = ANY(:ids)"),
                {"ids": solicitudes},
            )

        db.execute(
            text(
                "DELETE FROM cr_creditos "
                "WHERE cliente_id=:cliente AND cod_cuenta_credito LIKE 'CRED-MOB-%'"
            ),
            {"cliente": cliente},
        )
        db.execute(
            text(
                "DELETE FROM cr_movimientos "
                "WHERE cliente_id=:cliente AND "
                "(cod_operacion LIKE 'DES-%' OR concepto IN "
                "('Transferencia','Pago de cuota'))"
            ),
            {"cliente": cliente},
        )
        db.execute(
            text("DELETE FROM operaciones_cliente WHERE cliente_id=:cliente"),
            {"cliente": cliente},
        )
        db.execute(
            text(
                "DELETE FROM notificaciones WHERE cliente_id=:cliente "
                "AND tipo IN ('desembolsado','rechazado','condicionado')"
            ),
            {"cliente": cliente},
        )
        db.execute(
            text(
                "UPDATE cr_cuentas_ahorro SET saldo_capital=5000, saldo_interes=0 "
                "WHERE cliente_id=:cliente"
            ),
            {"cliente": cliente},
        )
        db.commit()
        print("Demo reiniciada. Cliente 40000001 listo con saldo S/ 5,000.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
