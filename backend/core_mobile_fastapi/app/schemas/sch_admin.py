from pydantic import BaseModel


class DecisionIn(BaseModel):
    decision: str
    monto_aprobado: float | None = None
    motivo: str | None = None


class CompletarExpedienteIn(BaseModel):
    ingresos_estimados: float
    gastos_mensuales: float = 0
    patrimonio_estimado: float = 0
    lat: float | None = None
    lng: float | None = None
    firma_cliente_base64: str
    consentimiento_base64: str
