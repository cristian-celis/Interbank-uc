-- Flujo cliente -> vendedor -> comite web -> desembolso.

CREATE TABLE IF NOT EXISTS solicitudes_decisiones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id    UUID NOT NULL REFERENCES solicitudes_credito(id) ON DELETE CASCADE,
    asesor_decisor_id UUID NOT NULL REFERENCES asesores(id),
    decision        VARCHAR(20) NOT NULL CHECK (decision IN ('aprobado','rechazado','condicionado')),
    monto_aprobado  DECIMAL(12,2),
    motivo          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_decisiones_solicitud
    ON solicitudes_decisiones (solicitud_id, created_at DESC);
