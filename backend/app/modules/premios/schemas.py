from pydantic import BaseModel
from typing import Optional


class SoftDeletePremioRequest(BaseModel):
    """
    Datos necesarios para hacer soft delete de un premio.

    No se elimina físicamente el registro, solo se marca como eliminado.
    """

    id_usuario: int
    motivo: Optional[str] = "Eliminación lógica desde panel administrativo"