from decimal import Decimal, ROUND_HALF_UP
from fastapi import HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session


def redondear_monto(valor) -> Decimal:
    """
    Redondea montos económicos a 2 decimales.
    """
    return Decimal(valor).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def obtener_liga(db: Session, id_liga: int):
    liga = db.execute(
        text("""
            SELECT 
                id_liga,
                nombre,
                tipo_liga,
                modalidad_liga,
                precio_participacion,
                estado
            FROM liga
            WHERE id_liga = :id_liga
        """),
        {"id_liga": id_liga}
    ).mappings().first()

    if not liga:
        raise HTTPException(status_code=404, detail="Liga no encontrada")

    return liga


def obtener_ranking_liga(db: Session, id_liga: int):
    """
    Obtiene el ranking de una liga sumando los puntos de sus vaticinios.

    La suma se hace por miembro de liga para no mezclar puntos
    entre distintas ligas del mismo usuario.
    """
    ranking = db.execute(
        text("""
            SELECT
                lm.id_liga_miembro,
                lm.id_usuario,
                u.nombre_completo,
                COALESCE(SUM(p.puntos), 0) AS total_puntos
            FROM liga_miembro lm
            INNER JOIN usuario u 
                ON u.id_usuario = lm.id_usuario
            LEFT JOIN vaticinio v 
                ON v.id_liga_miembro = lm.id_liga_miembro
            LEFT JOIN puntaje p 
                ON p.id_vaticinio = v.id_vaticinio
            WHERE lm.id_liga = :id_liga
              AND lm.estado_membresia = 'activo'
            GROUP BY 
                lm.id_liga_miembro,
                lm.id_usuario,
                u.nombre_completo
            ORDER BY 
                total_puntos DESC,
                u.nombre_completo ASC
        """),
        {"id_liga": id_liga}
    ).mappings().all()

    return list(ranking)


def agrupar_por_puntos(ranking):
    """
    Agrupa usuarios con el mismo puntaje para manejar empates.
    """
    grupos = []

    for miembro in ranking:
        puntos = miembro["total_puntos"]

        if not grupos or grupos[-1]["puntos"] != puntos:
            grupos.append({
                "puntos": puntos,
                "miembros": [miembro]
            })
        else:
            grupos[-1]["miembros"].append(miembro)

    return grupos


def construir_distribucion_premios(total_recaudado: Decimal, ranking):
    """
    Construye la distribución de premios.

    Reglas usadas:
    - Sin empate: 1° 50%, 2° 25%, 3° 10%, último 10%.
    - Empate en 1°: 85% dividido entre empatados.
    - Empate en 2°: 35% dividido entre empatados.
    - Empate en 3°: 10% dividido entre empatados.
    """

    grupos = agrupar_por_puntos(ranking)

    if not grupos:
        raise HTTPException(
            status_code=400,
            detail="No existen participantes activos para calcular premios"
        )

    distribuciones = []

    primer_grupo = grupos[0]

    # Empate en primer lugar: se reparte 85%.
    if len(primer_grupo["miembros"]) > 1:
        distribuciones.append({
            "posicion_final": 1,
            "tipo_premio": "primer_lugar_empate",
            "porcentaje": Decimal("85.00"),
            "grupo": primer_grupo,
            "descripcion": "Empate en primer lugar: 85% dividido equitativamente"
        })

    else:
        # Primer lugar normal: 50%.
        distribuciones.append({
            "posicion_final": 1,
            "tipo_premio": "primer_lugar",
            "porcentaje": Decimal("50.00"),
            "grupo": primer_grupo,
            "descripcion": "Primer lugar: 50% del total recaudado"
        })

        # Segundo lugar.
        if len(grupos) >= 2:
            segundo_grupo = grupos[1]

            if len(segundo_grupo["miembros"]) > 1:
                porcentaje_segundo = Decimal("35.00")
                tipo_segundo = "segundo_lugar_empate"
                descripcion_segundo = "Empate en segundo lugar: 35% dividido equitativamente"
            else:
                porcentaje_segundo = Decimal("25.00")
                tipo_segundo = "segundo_lugar"
                descripcion_segundo = "Segundo lugar: 25% del total recaudado"

            distribuciones.append({
                "posicion_final": 2,
                "tipo_premio": tipo_segundo,
                "porcentaje": porcentaje_segundo,
                "grupo": segundo_grupo,
                "descripcion": descripcion_segundo
            })

            # Tercer lugar solo se calcula si el segundo lugar no ocupó el 35%.
            if len(segundo_grupo["miembros"]) == 1 and len(grupos) >= 3:
                tercer_grupo = grupos[2]

                distribuciones.append({
                    "posicion_final": 3,
                    "tipo_premio": "tercer_lugar",
                    "porcentaje": Decimal("10.00"),
                    "grupo": tercer_grupo,
                    "descripcion": "Tercer lugar: 10% del total recaudado"
                })

    # Premio al último lugar: 10%.
    ultimo_grupo = grupos[-1]

    distribuciones.append({
        "posicion_final": 4,
        "tipo_premio": "ultimo_lugar",
        "porcentaje": Decimal("10.00"),
        "grupo": ultimo_grupo,
        "descripcion": "Último lugar: 10% del total recaudado"
    })

    # Calcular montos.
    for distribucion in distribuciones:
        porcentaje = distribucion["porcentaje"] / Decimal("100")
        monto_grupo = redondear_monto(total_recaudado * porcentaje)
        cantidad_ganadores = len(distribucion["grupo"]["miembros"])
        monto_por_usuario = redondear_monto(monto_grupo / cantidad_ganadores)

        distribucion["monto_grupo"] = monto_grupo
        distribucion["monto_por_usuario"] = monto_por_usuario

    return distribuciones


def cerrar_liga_y_calcular_premios(db: Session, id_liga: int):
    """
    Cierra una liga de apuesta y calcula premios.

    Este proceso:
    1. Valida que la liga exista.
    2. Valida que sea liga de apuesta.
    3. Evita doble cierre.
    4. Calcula total recaudado, comisión, fondo global y monto neto.
    5. Calcula ranking.
    6. Maneja empates.
    7. Inserta cierre_liga, distribucion_premio y premio.
    """

    liga = obtener_liga(db, id_liga)

    if liga["modalidad_liga"] != "apuesta":
        raise HTTPException(
            status_code=400,
            detail="Las ligas de diversión no generan premios monetarios"
        )

    cierre_existente = db.execute(
        text("""
            SELECT id_cierre_liga
            FROM cierre_liga
            WHERE id_liga = :id_liga
        """),
        {"id_liga": id_liga}
    ).mappings().first()

    if cierre_existente:
        raise HTTPException(
            status_code=400,
            detail="Esta liga ya fue cerrada anteriormente"
        )

    ranking = obtener_ranking_liga(db, id_liga)

    participantes_activos = len(ranking)

    if participantes_activos == 0:
        raise HTTPException(
            status_code=400,
            detail="No hay participantes activos en la liga"
        )

    precio = Decimal(liga["precio_participacion"])
    total_recaudado = redondear_monto(precio * participantes_activos)

    comision = redondear_monto(total_recaudado * Decimal("0.05"))
    fondo_global = redondear_monto(total_recaudado * Decimal("0.01"))
    monto_neto = redondear_monto(total_recaudado * Decimal("0.95"))

    distribuciones = construir_distribucion_premios(total_recaudado, ranking)

    try:
        cierre = db.execute(
            text("""
                INSERT INTO cierre_liga (
                    id_liga,
                    total_recaudado,
                    comision,
                    fondo_global,
                    monto_neto,
                    promedio_puntos
                )
                VALUES (
                    :id_liga,
                    :total_recaudado,
                    :comision,
                    :fondo_global,
                    :monto_neto,
                    :promedio_puntos
                )
                RETURNING id_cierre_liga
            """),
            {
                "id_liga": id_liga,
                "total_recaudado": total_recaudado,
                "comision": comision,
                "fondo_global": fondo_global,
                "monto_neto": monto_neto,
                "promedio_puntos": calcular_promedio_puntos(ranking)
            }
        ).mappings().first()

        id_cierre_liga = cierre["id_cierre_liga"]

        premios_creados = []

        for distribucion in distribuciones:
            db.execute(
                text("""
                    INSERT INTO distribucion_premio (
                        id_cierre_liga,
                        posicion_final,
                        porcentaje,
                        monto,
                        descripcion
                    )
                    VALUES (
                        :id_cierre_liga,
                        :posicion_final,
                        :porcentaje,
                        :monto,
                        :descripcion
                    )
                """),
                {
                    "id_cierre_liga": id_cierre_liga,
                    "posicion_final": distribucion["posicion_final"],
                    "porcentaje": distribucion["porcentaje"],
                    "monto": distribucion["monto_grupo"],
                    "descripcion": distribucion["descripcion"]
                }
            )

            for miembro in distribucion["grupo"]["miembros"]:
                premio = db.execute(
                    text("""
                        INSERT INTO premio (
                            id_liga,
                            id_usuario,
                            tipo_premio,
                            monto,
                            descripcion
                        )
                        VALUES (
                            :id_liga,
                            :id_usuario,
                            :tipo_premio,
                            :monto,
                            :descripcion
                        )
                        RETURNING id_premio
                    """),
                    {
                        "id_liga": id_liga,
                        "id_usuario": miembro["id_usuario"],
                        "tipo_premio": distribucion["tipo_premio"],
                        "monto": distribucion["monto_por_usuario"],
                        "descripcion": distribucion["descripcion"]
                    }
                ).mappings().first()

                premios_creados.append({
                    "id_premio": premio["id_premio"],
                    "id_usuario": miembro["id_usuario"],
                    "usuario": miembro["nombre_completo"],
                    "tipo_premio": distribucion["tipo_premio"],
                    "monto": float(distribucion["monto_por_usuario"]),
                    "puntos": float(miembro["total_puntos"])
                })

        db.commit()

        return {
            "message": "Liga cerrada y premios calculados correctamente",
            "id_liga": id_liga,
            "id_cierre_liga": id_cierre_liga,
            "participantes_activos": participantes_activos,
            "total_recaudado": float(total_recaudado),
            "comision": float(comision),
            "fondo_global": float(fondo_global),
            "monto_neto": float(monto_neto),
            "premios": premios_creados
        }

    except Exception as error:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al cerrar la liga: {str(error)}"
        )


def calcular_promedio_puntos(ranking):
    if not ranking:
        return Decimal("0.00")

    total = sum(Decimal(r["total_puntos"]) for r in ranking)
    promedio = total / Decimal(len(ranking))

    return redondear_monto(promedio)


def obtener_cierre_liga(db: Session, id_liga: int):
    cierre = db.execute(
        text("""
            SELECT *
            FROM cierre_liga
            WHERE id_liga = :id_liga
        """),
        {"id_liga": id_liga}
    ).mappings().first()

    if not cierre:
        raise HTTPException(
            status_code=404,
            detail="La liga aún no tiene cierre registrado"
        )

    distribucion = db.execute(
        text("""
            SELECT *
            FROM distribucion_premio
            WHERE id_cierre_liga = :id_cierre_liga
            ORDER BY posicion_final ASC
        """),
        {"id_cierre_liga": cierre["id_cierre_liga"]}
    ).mappings().all()

    premios = db.execute(
        text("""
            SELECT
                p.id_premio,
                p.id_liga,
                p.id_usuario,
                u.nombre_completo,
                p.tipo_premio,
                p.monto,
                p.descripcion,
                p.fecha_asignacion
            FROM premio p
            INNER JOIN usuario u 
                ON u.id_usuario = p.id_usuario
            WHERE p.id_liga = :id_liga
              AND p.deleted_at IS NULL
            ORDER BY p.monto DESC
        """),
        {"id_liga": id_liga}
    ).mappings().all()

    return {
        "cierre": dict(cierre),
        "distribucion": [dict(row) for row in distribucion],
        "premios": [dict(row) for row in premios]
    }


def soft_delete_premio(db: Session, id_premio: int, id_usuario: int, motivo: str):
    """
    Elimina lógicamente un premio.

    No usa DELETE físico porque los premios deben conservar trazabilidad.
    """
    premio = db.execute(
        text("""
            UPDATE premio
            SET 
                deleted_at = NOW(),
                deleted_by = :id_usuario,
                motivo_eliminacion = :motivo
            WHERE id_premio = :id_premio
              AND deleted_at IS NULL
            RETURNING id_premio
        """),
        {
            "id_premio": id_premio,
            "id_usuario": id_usuario,
            "motivo": motivo
        }
    ).mappings().first()

    if not premio:
        raise HTTPException(
            status_code=404,
            detail="Premio no encontrado o ya fue eliminado"
        )

    db.commit()

    return {
        "message": "Premio eliminado lógicamente",
        "id_premio": id_premio
    }