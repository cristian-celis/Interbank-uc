from pydantic import BaseModel, model_validator
from typing import Optional
from app.core.credit_policy import validate_credit_terms


class SolicitudIn(BaseModel):
    # Solicitante / negocio
    numero_documento: str
    nombres: str = ""
    apellidos: str = ""
    telefono: Optional[str] = None
    tipo_negocio: Optional[str] = None
    nombre_negocio: Optional[str] = None
    ingresos_estimados: Optional[float] = None
    # Condiciones
    monto_solicitado: float
    plazo_meses: int
    moneda: str = "PEN"
    tipo_cuota: str = "mensual"
    garantia: str = "sin_garantia"
    destino_credito: Optional[str] = None
    cuota_estimada: Optional[float] = None
    tea_referencial: Optional[float] = None
    firma_cliente_base64: Optional[str] = None

    @model_validator(mode="after")
    def validate_official_credit_ranges(self):
        validate_credit_terms(
            amount=self.monto_solicitado,
            term_months=self.plazo_meses,
            tea=self.tea_referencial,
            destino_credito=self.destino_credito,
            tipo_negocio=self.tipo_negocio,
        )
        return self


class SolicitudCreada(BaseModel):
    id: str
    numero_expediente: str
    estado: str


class SolicitudResumen(BaseModel):
    id: str
    numero_expediente: str
    cliente_nombre: str
    monto_solicitado: float
    monto_aprobado: float
    estado: str
    created_at: Optional[str] = None
