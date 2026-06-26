from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.cfg_auth import get_current_supervisor
from app.core.cfg_database import get_db
from app.repositories import rep_admin
from app.schemas.sch_admin import DecisionIn

router = APIRouter()


@router.get("/solicitudes")
def solicitudes(
    estado: str | None = None,
    db: Session = Depends(get_db),
    supervisor: dict = Depends(get_current_supervisor),
):
    return rep_admin.listar_solicitudes(db, estado)


@router.post("/solicitudes/{solicitud_id}/decision")
def decidir(
    solicitud_id: str,
    data: DecisionIn,
    db: Session = Depends(get_db),
    supervisor: dict = Depends(get_current_supervisor),
):
    try:
        return rep_admin.decidir(
            db,
            solicitud_id,
            supervisor["asesor_id"],
            data.decision,
            data.monto_aprobado,
            data.motivo,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
