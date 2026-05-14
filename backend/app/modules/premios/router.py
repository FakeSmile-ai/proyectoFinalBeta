from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.shared.database import get_db
from app.modules.premios.schemas import SoftDeletePremioRequest
from app.modules.premios.service import (
    cerrar_liga_y_calcular_premios,
    obtener_cierre_liga,
    soft_delete_premio
)

router = APIRouter()


@router.post("/ligas/{id_liga}/cerrar")
def cerrar_liga(id_liga: int, db: Session = Depends(get_db)):
    """
    Cierra una liga de apuesta y calcula sus premios.
    """
    return cerrar_liga_y_calcular_premios(db, id_liga)


@router.get("/ligas/{id_liga}")
def consultar_premios_liga(id_liga: int, db: Session = Depends(get_db)):
    """
    Consulta el cierre, distribución y premios asignados de una liga.
    """
    return obtener_cierre_liga(db, id_liga)


@router.delete("/{id_premio}")
def eliminar_premio_logicamente(
    id_premio: int,
    request: SoftDeletePremioRequest,
    db: Session = Depends(get_db)
):
    """
    Realiza soft delete de un premio.
    """
    return soft_delete_premio(
        db=db,
        id_premio=id_premio,
        id_usuario=request.id_usuario,
        motivo=request.motivo
    )