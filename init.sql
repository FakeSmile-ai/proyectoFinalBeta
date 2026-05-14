-- ============================================================
-- INIT.SQL COMPLETO PARA POSTGRESQL 15 EN DOCKER
-- Base: pronosticos_futbol
-- Incluye creación de tablas + datos de prueba
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
--  SCRIPT DE CREACIÓN DE BASE DE DATOS PostgreSQL
--  Sistema de Pronósticos de Torneos de Fútbol
-- ============================================================

-- Crear base de datos (ejecutar como superusuario si es necesario)
-- CREATE DATABASE pronosticos_futbol
--     WITH ENCODING = 'UTF8'
--          LC_COLLATE = 'es_ES.UTF-8'
--          LC_CTYPE = 'es_ES.UTF-8'
--          TEMPLATE = template0;

-- \c pronosticos_futbol;

-- Eliminar tablas si existen (en orden inverso de dependencias)
DROP TABLE IF EXISTS audit_log             CASCADE;
DROP TABLE IF EXISTS distribucion_premio    CASCADE;
DROP TABLE IF EXISTS cierre_liga            CASCADE;
DROP TABLE IF EXISTS premio                 CASCADE;
DROP TABLE IF EXISTS invitacion_liga        CASCADE;
DROP TABLE IF EXISTS solicitud_ingreso      CASCADE;
DROP TABLE IF EXISTS puntaje                CASCADE;
DROP TABLE IF EXISTS vaticinio              CASCADE;
DROP TABLE IF EXISTS liga_miembro           CASCADE;
DROP TABLE IF EXISTS resultado_oficial      CASCADE;
DROP TABLE IF EXISTS partido                CASCADE;
DROP TABLE IF EXISTS liga                   CASCADE;
DROP TABLE IF EXISTS usuario                CASCADE;
DROP TABLE IF EXISTS rol                    CASCADE;
DROP TABLE IF EXISTS estadio                CASCADE;
DROP TABLE IF EXISTS sede                   CASCADE;
DROP TABLE IF EXISTS pais                   CASCADE;
DROP TABLE IF EXISTS grupo                  CASCADE;
DROP TABLE IF EXISTS fase                   CASCADE;
DROP TABLE IF EXISTS torneo                 CASCADE;

-- ============================================================
-- TABLA: torneo
-- ============================================================
CREATE TABLE torneo (
    id_torneo   SERIAL          PRIMARY KEY,
    nombre      VARCHAR(150)    NOT NULL,
    anio        SMALLINT        NOT NULL CHECK (anio >= 1900 AND anio <= 2100),
    estado      VARCHAR(30)     NOT NULL DEFAULT 'planificado'
                                CHECK (estado IN ('planificado','en_curso','finalizado','cancelado'))
);

COMMENT ON TABLE  torneo IS 'Torneos de fútbol (Copa del Mundo, Eurocopa, etc.)';
COMMENT ON COLUMN torneo.estado IS 'planificado | en_curso | finalizado | cancelado';

-- ============================================================
-- TABLA: fase
-- ============================================================
CREATE TABLE fase (
    id_fase     SERIAL          PRIMARY KEY,
    id_torneo   INT             NOT NULL REFERENCES torneo(id_torneo) ON DELETE CASCADE,
    nombre      VARCHAR(100)    NOT NULL,
    orden_fase  SMALLINT        NOT NULL CHECK (orden_fase > 0)
);

COMMENT ON TABLE fase IS 'Fases del torneo: Grupos, Octavos, Cuartos, Semis, Final, etc.';

-- ============================================================
-- TABLA: grupo
-- ============================================================
CREATE TABLE grupo (
    id_grupo    SERIAL          PRIMARY KEY,
    id_torneo   INT             NOT NULL REFERENCES torneo(id_torneo) ON DELETE CASCADE,
    nombre      VARCHAR(50)     NOT NULL
);

COMMENT ON TABLE grupo IS 'Grupos dentro de la fase de grupos de cada torneo';

-- ============================================================
-- TABLA: pais
-- ============================================================
CREATE TABLE pais (
    id_pais         SERIAL          PRIMARY KEY,
    nombre          VARCHAR(100)    NOT NULL UNIQUE,
    codigo_fifa     CHAR(3)         NOT NULL UNIQUE,
    confederacion   VARCHAR(20)     NOT NULL
                                    CHECK (confederacion IN ('UEFA','CONMEBOL','CONCACAF','CAF','AFC','OFC')),
    id_grupo        INT             REFERENCES grupo(id_grupo) ON DELETE SET NULL
);

COMMENT ON TABLE  pais IS 'Selecciones nacionales de fútbol';
COMMENT ON COLUMN pais.codigo_fifa IS 'Código de 3 letras de la FIFA (ej: ARG, BRA, ESP)';

-- ============================================================
-- TABLA: sede
-- ============================================================
CREATE TABLE sede (
    id_sede     SERIAL          PRIMARY KEY,
    nombre      VARCHAR(150)    NOT NULL,
    ciudad      VARCHAR(100)    NOT NULL,
    pais_sede   VARCHAR(100)    NOT NULL
);

COMMENT ON TABLE sede IS 'Ciudades / sedes del torneo';

-- ============================================================
-- TABLA: estadio
-- ============================================================
CREATE TABLE estadio (
    id_estadio  SERIAL          PRIMARY KEY,
    id_sede     INT             NOT NULL REFERENCES sede(id_sede) ON DELETE RESTRICT,
    nombre      VARCHAR(150)    NOT NULL,
    capacidad   INT             NOT NULL CHECK (capacidad > 0)
);

COMMENT ON TABLE estadio IS 'Estadios donde se disputan los partidos';

-- ============================================================
-- TABLA: rol
-- ============================================================
CREATE TABLE rol (
    id_rol      SERIAL          PRIMARY KEY,
    nombre_rol  VARCHAR(50)     NOT NULL UNIQUE,
    descripcion TEXT,
    estado      BOOLEAN         NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE rol IS 'Roles del sistema (administrador, jugador, árbitro, etc.)';

-- ============================================================
-- TABLA: usuario
-- ============================================================
CREATE TABLE usuario (
    id_usuario      SERIAL          PRIMARY KEY,
    nombre_completo VARCHAR(200)    NOT NULL,
    email           VARCHAR(254)    NOT NULL UNIQUE,
    password_hash   VARCHAR(255)    NOT NULL,
    estado          VARCHAR(20)     NOT NULL DEFAULT 'activo'
                                    CHECK (estado IN ('activo','inactivo','suspendido','pendiente')),
    id_rol          INT             NOT NULL REFERENCES rol(id_rol) ON DELETE RESTRICT,
    fecha_registro  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  usuario IS 'Usuarios registrados en la plataforma';
COMMENT ON COLUMN usuario.password_hash IS 'Hash bcrypt/argon2 de la contraseña. Nunca texto plano.';

-- ============================================================
-- TABLA: liga
-- ============================================================
CREATE TABLE liga (
    id_liga             SERIAL          PRIMARY KEY,
    nombre              VARCHAR(150)    NOT NULL,
    tipo_liga           VARCHAR(30)     NOT NULL DEFAULT 'publica'
                                        CHECK (tipo_liga IN ('publica','privada','invitacion')),
    precio_participacion NUMERIC(10,2)  NOT NULL DEFAULT 0 CHECK (precio_participacion >= 0),
    id_creador_usuario  INT             NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    id_admin_usuario    INT             NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    estado              VARCHAR(20)     NOT NULL DEFAULT 'activa'
                                        CHECK (estado IN ('activa','cerrada','suspendida','pendiente')),
    fecha_creacion      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);
ALTER TABLE liga
ADD COLUMN modalidad_liga VARCHAR(30) NOT NULL DEFAULT 'diversion'
CHECK (modalidad_liga IN ('diversion','apuesta'));

ALTER TABLE liga
ADD CONSTRAINT  uq_nombre_liga UNIQUE (nombre);

ALTER TABLE liga
ADD CONSTRAINT ck_liga_apuesta_precio CHECK ((modalidad_liga = 'apuesta' AND precio_participacion > 0) OR (modalidad_liga = 'diversion' AND precio_participacion >= 0));


COMMENT ON TABLE liga IS 'Ligas privadas/públicas de pronósticos entre usuarios';

-- ============================================================
-- TABLA: partido
-- ============================================================
CREATE TABLE partido (
    id_partido          SERIAL          PRIMARY KEY,
    id_torneo           INT             NOT NULL REFERENCES torneo(id_torneo) ON DELETE RESTRICT,
    id_fase             INT             NOT NULL REFERENCES fase(id_fase) ON DELETE RESTRICT,
    id_grupo            INT             REFERENCES grupo(id_grupo) ON DELETE SET NULL,
    id_estadio          INT             NOT NULL REFERENCES estadio(id_estadio) ON DELETE RESTRICT,
    id_equipo_local     INT             NOT NULL REFERENCES pais(id_pais) ON DELETE RESTRICT,
    id_equipo_visitante INT             NOT NULL REFERENCES pais(id_pais) ON DELETE RESTRICT,
    fecha_hora_inicio   TIMESTAMPTZ     NOT NULL,
    estado_partido      VARCHAR(20)     NOT NULL DEFAULT 'programado'
                                        CHECK (estado_partido IN ('programado','en_curso','finalizado','suspendido','postergado')),
    CONSTRAINT ck_equipos_distintos CHECK (id_equipo_local <> id_equipo_visitante)
);

COMMENT ON TABLE partido IS 'Partidos del torneo';

-- ============================================================
-- TABLA: resultado_oficial
-- ============================================================
CREATE TABLE resultado_oficial (
    id_resultado    SERIAL          PRIMARY KEY,
    id_partido      INT             NOT NULL UNIQUE REFERENCES partido(id_partido) ON DELETE CASCADE,
    goles_local     SMALLINT        NOT NULL CHECK (goles_local >= 0),
    goles_visitante SMALLINT        NOT NULL CHECK (goles_visitante >= 0),
    fecha_registro  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    bloqueado       BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE  resultado_oficial IS 'Resultado final oficial de cada partido';
COMMENT ON COLUMN resultado_oficial.bloqueado IS 'TRUE = resultado cerrado, no se puede modificar';

-- ============================================================
-- TABLA: liga_miembro
-- ============================================================
CREATE TABLE liga_miembro (
    id_liga_miembro     SERIAL          PRIMARY KEY,
    id_liga             INT             NOT NULL REFERENCES liga(id_liga) ON DELETE CASCADE,
    id_usuario          INT             NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    nombre_equipo       VARCHAR(100),
    rol_liga            VARCHAR(30)     NOT NULL DEFAULT 'participante'
                                        CHECK (rol_liga IN ('administrador','participante','espectador')),
    estado_membresia    VARCHAR(20)     NOT NULL DEFAULT 'activo'
                                        CHECK (estado_membresia IN ('activo','inactivo','suspendido','pendiente')),
    fecha_union         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_liga_usuario UNIQUE (id_liga, id_usuario)
);

COMMENT ON TABLE liga_miembro IS 'Relación entre usuarios y ligas a las que pertenecen';

-- ============================================================
-- TABLA: vaticinio
-- ============================================================
CREATE TABLE vaticinio (
    id_vaticinio        SERIAL          PRIMARY KEY,
    id_liga_miembro     INT             NOT NULL REFERENCES liga_miembro(id_liga_miembro) ON DELETE CASCADE,
    id_partido          INT             NOT NULL REFERENCES partido(id_partido) ON DELETE CASCADE,
    goles_local_pred    SMALLINT        NOT NULL CHECK (goles_local_pred >= 0),
    goles_visitante_pred SMALLINT       NOT NULL CHECK (goles_visitante_pred >= 0),
    fecha_registro      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    fecha_modificacion  TIMESTAMPTZ,
    CONSTRAINT uq_vaticinio UNIQUE (id_liga_miembro, id_partido)
);

COMMENT ON TABLE vaticinio IS 'Pronósticos realizados por los miembros de cada liga';

-- ============================================================
-- TABLA: puntaje
-- ============================================================
CREATE TABLE puntaje (
    id_puntaje      SERIAL          PRIMARY KEY,
    id_vaticinio    INT             NOT NULL UNIQUE REFERENCES vaticinio(id_vaticinio) ON DELETE CASCADE,
    puntos          NUMERIC(6,2)    NOT NULL DEFAULT 0,
    acerto_resultado BOOLEAN        NOT NULL DEFAULT FALSE,
    acerto_marcador  BOOLEAN        NOT NULL DEFAULT FALSE,
    fecha_calculo   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE puntaje IS 'Puntos calculados para cada vaticinio una vez conocido el resultado oficial';

-- ============================================================
-- TABLA: solicitud_ingreso
-- ============================================================
CREATE TABLE solicitud_ingreso (
    id_solicitud        SERIAL          PRIMARY KEY,
    id_liga             INT             NOT NULL REFERENCES liga(id_liga) ON DELETE CASCADE,
    id_usuario          INT             NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    estado              VARCHAR(20)     NOT NULL DEFAULT 'pendiente'
                                        CHECK (estado IN ('pendiente','aprobada','rechazada','cancelada')),
    fecha_solicitud     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    fecha_resolucion    TIMESTAMPTZ,
    CONSTRAINT uq_solicitud UNIQUE (id_liga, id_usuario)
);

COMMENT ON TABLE solicitud_ingreso IS 'Solicitudes de usuarios para unirse a una liga privada';

-- ============================================================
-- TABLA: invitacion_liga
-- ============================================================
CREATE TABLE invitacion_liga (
    id_invitacion   SERIAL          PRIMARY KEY,
    id_liga         INT             NOT NULL REFERENCES liga(id_liga) ON DELETE CASCADE,
    email_destino   VARCHAR(254)    NOT NULL,
    token           UUID            NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    fecha_envio     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    estado          VARCHAR(20)     NOT NULL DEFAULT 'pendiente'
                                    CHECK (estado IN ('pendiente','aceptada','rechazada','expirada'))
);

COMMENT ON TABLE invitacion_liga IS 'Invitaciones enviadas por email para unirse a una liga';

-- ============================================================
-- TABLA: cierre_liga
-- ============================================================
CREATE TABLE cierre_liga (
    id_cierre_liga  SERIAL          PRIMARY KEY,
    id_liga         INT             NOT NULL UNIQUE REFERENCES liga(id_liga) ON DELETE RESTRICT,
    total_recaudado NUMERIC(12,2)   NOT NULL DEFAULT 0,
    comision        NUMERIC(12,2)   NOT NULL DEFAULT 0,
    fondo_global    NUMERIC(12,2)   NOT NULL DEFAULT 0,
    monto_neto      NUMERIC(12,2)   NOT NULL DEFAULT 0,
    promedio_puntos NUMERIC(8,2),
    fecha_cierre    TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cierre_liga IS 'Registro del cierre económico de una liga al finalizar el torneo';

-- ============================================================
-- TABLA: distribucion_premio
-- ============================================================
CREATE TABLE distribucion_premio (
    id_distribucion SERIAL          PRIMARY KEY,
    id_cierre_liga  INT             NOT NULL REFERENCES cierre_liga(id_cierre_liga) ON DELETE CASCADE,
    posicion_final  SMALLINT        NOT NULL CHECK (posicion_final > 0),
    porcentaje      NUMERIC(5,2)    NOT NULL CHECK (porcentaje > 0 AND porcentaje <= 100),
    monto           NUMERIC(12,2)   NOT NULL DEFAULT 0,
    descripcion     TEXT,
    CONSTRAINT uq_posicion_cierre UNIQUE (id_cierre_liga, posicion_final)
);

COMMENT ON TABLE distribucion_premio IS 'Distribución porcentual del premio por posición en cada cierre de liga';

-- ============================================================
-- TABLA: premio
-- ============================================================
CREATE TABLE premio (
    id_premio       SERIAL          PRIMARY KEY,
    id_liga         INT             NOT NULL REFERENCES liga(id_liga) ON DELETE RESTRICT,
    id_usuario      INT             NOT NULL REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
    tipo_premio     VARCHAR(50)     NOT NULL,
    monto           NUMERIC(12,2)   NOT NULL DEFAULT 0,
    descripcion     TEXT,
    fecha_asignacion TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE premio IS 'Premios asignados a usuarios ganadores de una liga';

-- ============================================================
-- TABLA: audit_log (auditoría de cambios)
-- ============================================================
CREATE TABLE audit_log (
    id_audit_log      SERIAL PRIMARY KEY,
    tabla_afectada    VARCHAR(100) NOT NULL,
    operacion         VARCHAR(10)  NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    id_registro       TEXT,
    datos_anteriores  JSONB,
    datos_nuevos      JSONB,
    usuario_bd        VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    fecha_evento      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE audit_log IS 'Bitácora de auditoría para registrar cambios críticos del sistema';

-- ============================================================
-- ÍNDICES para mejorar el rendimiento
-- ============================================================
CREATE INDEX idx_partido_torneo         ON partido(id_torneo);
CREATE INDEX idx_partido_fase           ON partido(id_fase);
CREATE INDEX idx_partido_fecha          ON partido(fecha_hora_inicio);
CREATE INDEX idx_vaticinio_liga_miembro ON vaticinio(id_liga_miembro);
CREATE INDEX idx_vaticinio_partido      ON vaticinio(id_partido);
CREATE INDEX idx_liga_miembro_liga      ON liga_miembro(id_liga);
CREATE INDEX idx_liga_miembro_usuario   ON liga_miembro(id_usuario);
CREATE INDEX idx_puntaje_vaticinio      ON puntaje(id_vaticinio);
CREATE INDEX idx_solicitud_liga         ON solicitud_ingreso(id_liga);
CREATE INDEX idx_solicitud_usuario      ON solicitud_ingreso(id_usuario);
CREATE INDEX idx_invitacion_email       ON invitacion_liga(email_destino);
CREATE INDEX idx_usuario_email          ON usuario(email);
CREATE INDEX idx_pais_grupo             ON pais(id_grupo);
CREATE INDEX idx_audit_log_fecha_evento ON audit_log(fecha_evento DESC);
CREATE INDEX idx_audit_log_tabla        ON audit_log(tabla_afectada);
CREATE INDEX idx_audit_log_operacion    ON audit_log(operacion);

-- ============================================================
-- SOFT DELETE para no perder registros históricos
-- ============================================================
ALTER TABLE premio
ADD COLUMN deleted_at TIMESTAMPTZ,
ADD COLUMN deleted_by INT REFERENCES usuario(id_usuario),
ADD COLUMN motivo_eliminacion TEXT;

ALTER TABLE cierre_liga
ADD COLUMN deleted_at TIMESTAMPTZ,
ADD COLUMN deleted_by INT REFERENCES usuario(id_usuario),
ADD COLUMN motivo_eliminacion TEXT;

ALTER TABLE distribucion_premio
ADD COLUMN deleted_at TIMESTAMPTZ,
ADD COLUMN deleted_by INT REFERENCES usuario(id_usuario),
ADD COLUMN motivo_eliminacion TEXT;

-- ============================================================
-- Creación de función trigger para auditoría
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    datos_json JSONB;
    id_detectado TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        datos_json := to_jsonb(NEW);
    ELSE
        datos_json := to_jsonb(OLD);
    END IF;

    id_detectado := CASE TG_TABLE_NAME
        WHEN 'liga' THEN datos_json ->> 'id_liga'
        WHEN 'premio' THEN datos_json ->> 'id_premio'
        WHEN 'cierre_liga' THEN datos_json ->> 'id_cierre_liga'
        WHEN 'distribucion_premio' THEN datos_json ->> 'id_distribucion'
        WHEN 'resultado_oficial' THEN datos_json ->> 'id_resultado'
        ELSE (
            SELECT value
            FROM jsonb_each_text(datos_json)
            WHERE key LIKE 'id_%'
            LIMIT 1
        )
    END;

    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (
            tabla_afectada,
            operacion,
            id_registro,
            datos_anteriores,
            datos_nuevos,
            usuario_bd,
            fecha_evento
        )
        VALUES (
            TG_TABLE_NAME,
            TG_OP,
            id_detectado,
            NULL,
            to_jsonb(NEW),
            CURRENT_USER,
            NOW()
        );

        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (
            tabla_afectada,
            operacion,
            id_registro,
            datos_anteriores,
            datos_nuevos,
            usuario_bd,
            fecha_evento
        )
        VALUES (
            TG_TABLE_NAME,
            TG_OP,
            id_detectado,
            to_jsonb(OLD),
            to_jsonb(NEW),
            CURRENT_USER,
            NOW()
        );

        RETURN NEW;
    END IF;

    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (
            tabla_afectada,
            operacion,
            id_registro,
            datos_anteriores,
            datos_nuevos,
            usuario_bd,
            fecha_evento
        )
        VALUES (
            TG_TABLE_NAME,
            TG_OP,
            id_detectado,
            to_jsonb(OLD),
            NULL,
            CURRENT_USER,
            NOW()
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Aplicación de audit_log a tablas críticas
-- ============================================================
CREATE TRIGGER trg_audit_premio
AFTER INSERT OR UPDATE OR DELETE ON premio
FOR EACH ROW
EXECUTE FUNCTION fn_audit_log();

CREATE TRIGGER trg_audit_cierre_liga
AFTER INSERT OR UPDATE OR DELETE ON cierre_liga
FOR EACH ROW
EXECUTE FUNCTION fn_audit_log();

CREATE TRIGGER trg_audit_distribucion_premio
AFTER INSERT OR UPDATE OR DELETE ON distribucion_premio
FOR EACH ROW
EXECUTE FUNCTION fn_audit_log();

CREATE TRIGGER trg_audit_resultado_oficial
AFTER INSERT OR UPDATE OR DELETE ON resultado_oficial
FOR EACH ROW
EXECUTE FUNCTION fn_audit_log();

CREATE TRIGGER trg_audit_liga
AFTER INSERT OR UPDATE OR DELETE ON liga
FOR EACH ROW
EXECUTE FUNCTION fn_audit_log();

-- ============================================================
-- FIN DEL SCRIPT DE CREACIÓN
-- ============================================================

-- ============================================================
-- DATOS DE PRUEBA
-- ============================================================

-- ============================================================
--  SCRIPT DE DATOS DE PRUEBA (SEED)
--  Sistema de Pronósticos de Torneos de Fútbol
--  Escenario: Copa del Mundo 2026
-- ============================================================

-- Limpiar datos en orden inverso de dependencias
TRUNCATE TABLE distribucion_premio, premio, cierre_liga,
              invitacion_liga, solicitud_ingreso, puntaje,
              vaticinio, liga_miembro, resultado_oficial,
              partido, liga, usuario, rol, estadio, sede,
              pais, grupo, fase, torneo
RESTART IDENTITY CASCADE;

-- ============================================================
-- 1. ROL
-- ============================================================
INSERT INTO rol (nombre_rol, descripcion, estado) VALUES
('administrador', 'Administrador global de la plataforma', TRUE),
('moderador',     'Modera ligas y gestiona contenido',     TRUE),
('jugador',       'Usuario participante en ligas',         TRUE),
('espectador',    'Solo puede ver, no participar',         TRUE);

-- ============================================================
-- 2. USUARIO
-- ============================================================
-- Contraseña de ejemplo: 'Password123!' hasheada con bcrypt
INSERT INTO usuario (nombre_completo, email, password_hash, estado, id_rol) VALUES
('Admin Sistema',      'admin@pronosticos.com',     '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 1),
('Carlos Rodríguez',   'carlos.r@email.com',        '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 3),
('María González',     'maria.g@email.com',         '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 3),
('Luis Martínez',      'luis.m@email.com',          '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 3),
('Ana Torres',         'ana.t@email.com',           '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 3),
('Pedro Sánchez',      'pedro.s@email.com',         '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 3),
('Laura Jiménez',      'laura.j@email.com',         '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 3),
('Moderador Liga',     'mod@pronosticos.com',       '$2b$12$KIX9GsFVu9P9Q5LXYv0sCuDpRqTzBIJmMoNpKaWzCUlNaGjRi9Oma', 'activo', 2);

-- ============================================================
-- 3. TORNEO
-- ============================================================
INSERT INTO torneo (nombre, anio, estado) VALUES
('Copa del Mundo FIFA 2026',     2026, 'en_curso'),
('Eurocopa 2024',                2024, 'finalizado'),
('Copa América 2024',            2024, 'finalizado');

-- ============================================================
-- 4. FASE (para el torneo 1 - Mundial 2026)
-- ============================================================
INSERT INTO fase (id_torneo, nombre, orden_fase) VALUES
(1, 'Fase de Grupos',       1),
(1, 'Octavos de Final',     2),
(1, 'Cuartos de Final',     3),
(1, 'Semifinal',            4),
(1, 'Tercer Puesto',        5),
(1, 'Final',                6),
-- Fases Eurocopa 2024
(2, 'Fase de Grupos',       1),
(2, 'Octavos de Final',     2),
(2, 'Cuartos de Final',     3),
(2, 'Semifinal',            4),
(2, 'Final',                5);

-- ============================================================
-- 5. GRUPO (para el torneo 1 - Mundial 2026)
-- ============================================================
INSERT INTO grupo (id_torneo, nombre) VALUES
(1, 'Grupo A'),
(1, 'Grupo B'),
(1, 'Grupo C'),
(1, 'Grupo D'),
(1, 'Grupo E'),
(1, 'Grupo F'),
(1, 'Grupo G'),
(1, 'Grupo H');

-- ============================================================
-- 6. PAIS (selecciones participantes en Mundial 2026)
-- ============================================================
INSERT INTO pais (nombre, codigo_fifa, confederacion, id_grupo) VALUES
('Argentina',         'ARG', 'CONMEBOL', 1),
('Brasil',            'BRA', 'CONMEBOL', 1),
('España',            'ESP', 'UEFA',     2),
('Francia',           'FRA', 'UEFA',     2),
('Alemania',          'ALE', 'UEFA',     3),
('Portugal',          'POR', 'UEFA',     3),
('México',            'MEX', 'CONCACAF', 4),
('Estados Unidos',    'USA', 'CONCACAF', 4),
('Marruecos',         'MAR', 'CAF',      5),
('Senegal',           'SEN', 'CAF',      5),
('Japón',             'JPN', 'AFC',      6),
('Australia',         'AUS', 'AFC',      6),
('Uruguay',           'URU', 'CONMEBOL', 7),
('Colombia',          'COL', 'CONMEBOL', 7),
('Países Bajos',      'NED', 'UEFA',     8),
('Inglaterra',        'ENG', 'UEFA',     8);

-- ============================================================
-- 7. SEDE
-- ============================================================
INSERT INTO sede (nombre, ciudad, pais_sede) VALUES
('Sede Nueva York',      'Nueva York',    'Estados Unidos'),
('Sede Los Ángeles',     'Los Ángeles',   'Estados Unidos'),
('Sede Ciudad de México','Ciudad de México','México'),
('Sede Guadalajara',     'Guadalajara',   'México'),
('Sede Toronto',         'Toronto',       'Canadá'),
('Sede Vancouver',       'Vancouver',     'Canadá');

-- ============================================================
-- 8. ESTADIO
-- ============================================================
INSERT INTO estadio (id_sede, nombre, capacidad) VALUES
(1, 'MetLife Stadium',          82500),
(1, 'Giants Stadium',           76500),
(2, 'SoFi Stadium',             70240),
(2, 'Rose Bowl',                90888),
(3, 'Estadio Azteca',           87523),
(3, 'Estadio Olímpico Universitario', 72449),
(4, 'Estadio Akron',            45000),
(5, 'BMO Field',                30000),
(6, 'BC Place',                 54500);

-- ============================================================
-- 9. PARTIDO (Fase de Grupos - algunos partidos representativos)
-- ============================================================
INSERT INTO partido (id_torneo, id_fase, id_grupo, id_estadio, id_equipo_local, id_equipo_visitante, fecha_hora_inicio, estado_partido) VALUES
-- Grupo A
(1, 1, 1, 5, 1, 2,  '2026-06-11 18:00:00-06', 'finalizado'),  -- ARG vs BRA
-- Grupo B
(1, 1, 2, 1, 3, 4,  '2026-06-12 15:00:00-04', 'finalizado'),  -- ESP vs FRA
-- Grupo C
(1, 1, 3, 3, 5, 6,  '2026-06-13 19:00:00-05', 'finalizado'),  -- ALE vs POR
-- Grupo D
(1, 1, 4, 3, 7, 8,  '2026-06-14 15:00:00-05', 'finalizado'),  -- MEX vs USA
-- Grupo E
(1, 1, 5, 1, 9, 10, '2026-06-15 12:00:00-04', 'finalizado'),  -- MAR vs SEN
-- Grupo F
(1, 1, 6, 9, 11, 12,'2026-06-16 09:00:00-07', 'finalizado'),  -- JPN vs AUS
-- Grupo G
(1, 1, 7, 5, 13, 14,'2026-06-17 18:00:00-06', 'finalizado'),  -- URU vs COL
-- Grupo H
(1, 1, 8, 1, 15, 16,'2026-06-18 15:00:00-04', 'finalizado'),  -- NED vs ENG
-- Semifinales
(1, 4, NULL, 1, 1, 3, '2026-07-09 15:00:00-04', 'finalizado'), -- ARG vs ESP
(1, 4, NULL, 5, 2, 4, '2026-07-10 18:00:00-06', 'finalizado'), -- BRA vs FRA
-- Final
(1, 6, NULL, 1, 1, 4, '2026-07-19 15:00:00-04', 'programado'); -- ARG vs FRA

-- ============================================================
-- 10. RESULTADO_OFICIAL (partidos ya finalizados)
-- ============================================================
INSERT INTO resultado_oficial (id_partido, goles_local, goles_visitante, bloqueado) VALUES
(1,  3, 1, TRUE),   -- ARG 3-1 BRA
(2,  2, 2, TRUE),   -- ESP 2-2 FRA
(3,  1, 0, TRUE),   -- ALE 1-0 POR
(4,  2, 3, TRUE),   -- MEX 2-3 USA
(5,  1, 1, TRUE),   -- MAR 1-1 SEN
(6,  2, 1, TRUE),   -- JPN 2-1 AUS
(7,  1, 0, TRUE),   -- URU 1-0 COL
(8,  0, 1, TRUE),   -- NED 0-1 ENG
(9,  1, 0, TRUE),   -- ARG 1-0 ESP
(10, 2, 1, TRUE);   -- BRA 2-1 FRA

-- ============================================================
-- 11. LIGA
-- ============================================================
INSERT INTO liga (
    nombre,
    tipo_liga,
    modalidad_liga,
    precio_participacion,
    id_creador_usuario,
    id_admin_usuario,
    estado
) VALUES
('Liga Amigos del Mundial 2026', 'privada', 'apuesta', 500.00, 2, 2, 'activa'),
('Liga Oficina Central', 'privada', 'apuesta', 200.00, 3, 3, 'activa'),
('Liga Pública Fanáticos FIFA', 'publica', 'diversion', 0.00, 1, 1, 'activa'),
('Liga Champions Quiniela', 'invitacion', 'apuesta', 1000.00, 4, 4, 'activa');

-- ============================================================
-- 12. LIGA_MIEMBRO
-- ============================================================
INSERT INTO liga_miembro (id_liga, id_usuario, nombre_equipo, rol_liga, estado_membresia) VALUES
-- Liga 1
(1, 2, 'Albicelestes FC',     'administrador', 'activo'),
(1, 3, 'Seleção Dream',       'participante',  'activo'),
(1, 4, 'Tri Campeón',         'participante',  'activo'),
(1, 5, 'La Roja Power',       'participante',  'activo'),
-- Liga 2
(2, 3, 'Oficina Goleadora',   'administrador', 'activo'),
(2, 6, 'Los Cafeteros',       'participante',  'activo'),
(2, 7, 'Euro Warriors',       'participante',  'activo'),
-- Liga 3 (pública)
(3, 2, 'Team Mundial',        'participante',  'activo'),
(3, 5, 'Globe United',        'participante',  'activo'),
(3, 6, 'WorldCup Kings',      'participante',  'activo'),
-- Liga 4
(4, 4, 'Quiniela Elite',      'administrador', 'activo'),
(4, 7, 'Prediction Masters',  'participante',  'activo');

-- ============================================================
-- 13. VATICINIO
-- ============================================================
INSERT INTO vaticinio (id_liga_miembro, id_partido, goles_local_pred, goles_visitante_pred) VALUES
-- Miembro 1 (Carlos, Liga 1) pronostica
(1, 1,  3, 1),  -- ARG 3-1 BRA ✓ marcador exacto
(1, 2,  2, 1),  -- ESP 2-1 FRA (resultado ok, marcador no)
(1, 9,  1, 0),  -- ARG 1-0 ESP ✓ marcador exacto
(1, 10, 2, 0),  -- BRA 2-0 FRA (resultado ok)
-- Miembro 2 (María, Liga 1) pronostica
(2, 1,  2, 0),  -- ARG 2-0 BRA (resultado correcto)
(2, 2,  1, 2),  -- ESP 1-2 FRA (resultado incorrecto)
(2, 9,  2, 1),  -- ARG 2-1 ESP (resultado ok)
-- Miembro 5 (Pedro, Liga 2) pronostica
(5, 3,  1, 0),  -- ALE 1-0 POR ✓ marcador exacto
(5, 4,  1, 2),  -- MEX 1-2 USA (resultado ok)
(5, 5,  1, 0),  -- MAR 1-0 SEN (resultado incorrecto)
-- Miembro 8 (Carlos, Liga 3) pronostica
(8, 1,  3, 1),  -- ARG 3-1 BRA ✓ marcador exacto
(8, 6,  2, 1);  -- JPN 2-1 AUS ✓ marcador exacto

-- ============================================================
-- 14. PUNTAJE (sistema: 3 pts marcador exacto, 1 pt resultado)
-- ============================================================
INSERT INTO puntaje (id_vaticinio, puntos, acerto_resultado, acerto_marcador) VALUES
(1,  3, TRUE,  TRUE ),  -- ARG 3-1 BRA exacto
(2,  1, TRUE,  FALSE),  -- ESP vs FRA resultado ok
(3,  3, TRUE,  TRUE ),  -- ARG 1-0 ESP exacto
(4,  1, TRUE,  FALSE),  -- BRA vs FRA resultado ok
(5,  1, TRUE,  FALSE),  -- ARG vs BRA resultado ok
(6,  0, FALSE, FALSE),  -- ESP vs FRA incorrecto
(7,  1, TRUE,  FALSE),  -- ARG vs ESP resultado ok
(8,  3, TRUE,  TRUE ),  -- ALE 1-0 POR exacto
(9,  1, TRUE,  FALSE),  -- MEX vs USA resultado ok
(10, 0, FALSE, FALSE),  -- MAR vs SEN incorrecto
(11, 3, TRUE,  TRUE ),  -- ARG 3-1 BRA exacto
(12, 3, TRUE,  TRUE );  -- JPN 2-1 AUS exacto

-- ============================================================
-- 15. SOLICITUD_INGRESO
-- ============================================================
INSERT INTO solicitud_ingreso (id_liga, id_usuario, estado, fecha_solicitud, fecha_resolucion) VALUES
(1, 6, 'aprobada',  NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days'),
(1, 7, 'rechazada', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days'),
(4, 5, 'pendiente', NOW() - INTERVAL '1 day',  NULL),
(2, 4, 'aprobada',  NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days');

-- ============================================================
-- 16. INVITACION_LIGA
-- ============================================================
INSERT INTO invitacion_liga (id_liga, email_destino, estado) VALUES
(1, 'amigo1@email.com',  'pendiente'),
(1, 'amigo2@email.com',  'aceptada'),
(4, 'invitado@email.com','pendiente'),
(2, 'colega@email.com',  'expirada');

-- ============================================================
-- 17. CIERRE_LIGA (solo para ligas con precio > 0 ya cerradas)
-- ============================================================
-- Simulamos cierre de una liga de ejemplo (Liga 2 ya cerrada)
INSERT INTO cierre_liga (id_liga, total_recaudado, comision, fondo_global, monto_neto, promedio_puntos, fecha_cierre) VALUES
(2, 600.00, 30.00, 570.00, 570.00, 4.50, NOW() - INTERVAL '1 day');

-- ============================================================
-- 18. DISTRIBUCION_PREMIO
-- ============================================================
INSERT INTO distribucion_premio (id_cierre_liga, posicion_final, porcentaje, monto, descripcion) VALUES
(1, 1, 60.00, 342.00, 'Primer lugar: campeón de la liga'),
(1, 2, 30.00, 171.00, 'Segundo lugar'),
(1, 3, 10.00,  57.00, 'Tercer lugar');

-- ============================================================
-- 19. PREMIO (asignado al ganador de la Liga 2)
-- ============================================================
INSERT INTO premio (id_liga, id_usuario, tipo_premio, monto, descripcion) VALUES
(2, 3, 'efectivo', 342.00, 'Premio por primer lugar - Liga Oficina Central'),
(2, 6, 'efectivo', 171.00, 'Premio por segundo lugar - Liga Oficina Central'),
(2, 7, 'efectivo',  57.00, 'Premio por tercer lugar - Liga Oficina Central');

-- ============================================================
-- VERIFICACIÓN RÁPIDA DE DATOS
-- ============================================================
DO $$
DECLARE
    v_torneos   INT;
    v_partidos  INT;
    v_usuarios  INT;
    v_vatinios  INT;
BEGIN
    SELECT COUNT(*) INTO v_torneos  FROM torneo;
    SELECT COUNT(*) INTO v_partidos FROM partido;
    SELECT COUNT(*) INTO v_usuarios FROM usuario;
    SELECT COUNT(*) INTO v_vatinios FROM vaticinio;
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Seed completado exitosamente:';
    RAISE NOTICE '  Torneos   : %', v_torneos;
    RAISE NOTICE '  Partidos  : %', v_partidos;
    RAISE NOTICE '  Usuarios  : %', v_usuarios;
    RAISE NOTICE '  Vatinios  : %', v_vatinios;
    RAISE NOTICE '================================================';
END $$;

-- ============================================================
-- CONSULTAS DE EJEMPLO ÚTILES
-- ============================================================

-- Top 5 de la Liga 1 por puntos totales
/*
SELECT
    u.nombre_completo,
    lm.nombre_equipo,
    SUM(p.puntos)   AS total_puntos,
    COUNT(CASE WHEN p.acerto_marcador THEN 1 END) AS marcadores_exactos
FROM liga_miembro lm
JOIN usuario u ON u.id_usuario = lm.id_usuario
JOIN vaticinio v ON v.id_liga_miembro = lm.id_liga_miembro
JOIN puntaje p ON p.id_vaticinio = v.id_vaticinio
WHERE lm.id_liga = 1
GROUP BY u.nombre_completo, lm.nombre_equipo
ORDER BY total_puntos DESC
LIMIT 5;
*/

-- Partidos pendientes de pronosticar por un usuario en una liga
/*
SELECT
    pa.id_partido,
    eq_local.nombre  AS local,
    eq_vis.nombre    AS visitante,
    pa.fecha_hora_inicio
FROM partido pa
JOIN pais eq_local ON eq_local.id_pais = pa.id_equipo_local
JOIN pais eq_vis   ON eq_vis.id_pais   = pa.id_equipo_visitante
WHERE pa.id_torneo = 1
  AND pa.estado_partido = 'programado'
  AND pa.id_partido NOT IN (
        SELECT v.id_partido
        FROM vaticinio v
        JOIN liga_miembro lm ON lm.id_liga_miembro = v.id_liga_miembro
        WHERE lm.id_liga = 1 AND lm.id_usuario = 2
      )
ORDER BY pa.fecha_hora_inicio;
*/

-- ============================================================
-- FIN DEL SCRIPT DE SEED
-- ============================================================
