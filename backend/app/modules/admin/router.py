from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.shared.database import get_db
from app.modules.admin.service import (
    listar_audit_log,
    obtener_dashboard_global,
    obtener_reporte_actividad
)

router = APIRouter()


@router.get("/audit-log")
def consultar_auditoria(
    tabla: str | None = Query(default=None),
    operacion: str | None = Query(default=None),
    limite: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db)
):
    """
    Consulta la bitácora de auditoría del sistema.
    """
    return listar_audit_log(
        db=db,
        tabla=tabla,
        operacion=operacion,
        limite=limite
    )


@router.get("/dashboard-global")
def dashboard_global(db: Session = Depends(get_db)):
    """
    Devuelve totales generales para el panel administrativo.
    """
    return obtener_dashboard_global(db)


@router.get("/reportes/actividad")
def reporte_actividad(db: Session = Depends(get_db)):
    """
    Devuelve actividad agrupada por tabla y operación.
    """
    return obtener_reporte_actividad(db)