-- Estructura (SIN DATOS) del esquema public, tal como estaba después de la
-- migración 20260910190500_agregar_usuario_gerardo. Es la base sobre la que
-- los tests de integración aplican las migraciones posteriores de
-- supabase/migrations (ver IntegracionIT). No tiene filas: ni animales, ni
-- personas, ni contraseñas.
--
-- Cómo se regenera (contra el Supabase local, con todas las migraciones corridas):
--   docker exec supabase_db_anpael_repo pg_dump -U postgres -d postgres \
--     --schema-only -n public --no-owner --no-privileges > esquema.sql
-- sacarle las líneas \restrict / \unrestrict, renombrar el archivo con la
-- última versión de _migraciones_aplicadas y actualizar
-- IntegracionIT.VERSION_ESQUEMA.

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: chk_identificacion_visual(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.chk_identificacion_visual() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if new.id_tipo_ident = 1 and new.id_establecimiento is null then
        raise exception 'identificacion VISUAL requiere id_establecimiento (caravana unica por CUIG)';
    end if;
    return new;
end;
$$;


--
-- Name: es_gestor(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.es_gestor() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    select coalesce(rol_actual() in ('PROPIETARIO','ENCARGADO'), false);
$$;


--
-- Name: es_propietario(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.es_propietario() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    select coalesce(rol_actual() = 'PROPIETARIO', false);
$$;


--
-- Name: forzar_autoria(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.forzar_autoria() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    if auth.uid() is not null then
        new.id_persona_registro := public.persona_actual();
    end if;
    return new;
end;
$$;


--
-- Name: FUNCTION forzar_autoria(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.forzar_autoria() IS 'Sobreescribe id_persona_registro con la persona de la sesion. Impide que un usuario atribuya su carga a otro. Si no hay sesion (migracion como owner), respeta el valor recibido.';


--
-- Name: mover_a_rodeo(integer, integer, date, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mover_a_rodeo(p_animal integer, p_rodeo integer, p_fecha date DEFAULT CURRENT_DATE, p_fecha_es_estimada boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
declare
    v_actual   integer;
    v_desde    date;
    v_nombre   text;
    v_anterior text;
begin
    select nombre into v_nombre from rodeo where id_rodeo = p_rodeo and activo;
    if v_nombre is null then
        return 'ERROR: el rodeo ' || p_rodeo || ' no existe o esta inactivo.';
    end if;

    select ar.id_rodeo, ar.fecha_desde into v_actual, v_desde
      from animal_rodeo ar
     where ar.id_animal = p_animal and ar.fecha_hasta is null;

    if v_actual = p_rodeo then
        return 'Sin cambios: el animal ya estaba en ' || v_nombre || '.';
    end if;

    if v_actual is not null then
        if p_fecha <= v_desde then
            return 'ERROR: la fecha ' || p_fecha || ' no es posterior a la de ingreso '
                   'al rodeo actual (' || v_desde || '). No se cambio nada.';
        end if;
        select r.nombre into v_anterior from rodeo r where r.id_rodeo = v_actual;
        update animal_rodeo set fecha_hasta = p_fecha
         where id_animal = p_animal and fecha_hasta is null;
    end if;

    insert into animal_rodeo (id_animal, id_rodeo, fecha_desde, fecha_desde_es_estimada)
    values (p_animal, p_rodeo, p_fecha, p_fecha_es_estimada);

    return coalesce('Movido de ' || v_anterior || ' a ', 'Asignado a ') || v_nombre ||
           ' el ' || p_fecha || '.';
end;
$$;


--
-- Name: mover_lote_a_rodeo(integer[], integer, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mover_lote_a_rodeo(p_animales integer[], p_rodeo integer, p_fecha date DEFAULT CURRENT_DATE) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
declare a integer; n_ok integer := 0; n_err integer := 0; r text;
begin
    foreach a in array p_animales loop
        r := mover_a_rodeo(a, p_rodeo, p_fecha);
        if r like 'ERROR%' then n_err := n_err + 1; else n_ok := n_ok + 1; end if;
    end loop;
    return n_ok || ' animales movidos, ' || n_err || ' con error.';
end;
$$;


--
-- Name: persona_actual(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.persona_actual() RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select p.id_persona
    from persona p
    where p.id_auth_user = auth.uid()
    limit 1;
$$;


--
-- Name: FUNCTION persona_actual(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.persona_actual() IS 'id_persona del usuario logueado, segun persona.id_auth_user = auth.uid(). NULL si el usuario todavia no fue vinculado a una fila de persona, o si la insercion la hace una migracion (que corre como owner, sin sesion).';


--
-- Name: rol_actual(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rol_actual() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select p.rol
    from persona p
    where p.id_auth_user = auth.uid()
    limit 1;
$$;


--
-- Name: FUNCTION rol_actual(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.rol_actual() IS 'Rol de la persona logueada, segun persona.id_auth_user = auth.uid(). NULL si el usuario logueado todavia no fue vinculado a una fila de persona.';


--
-- Name: sellar_validacion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sellar_validacion() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    new.revisado_en := now();
    if auth.uid() is not null then
        new.id_persona := public.persona_actual();
    end if;
    return new;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _migraciones_aplicadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._migraciones_aplicadas (
    version text NOT NULL,
    aplicada_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE _migraciones_aplicadas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public._migraciones_aplicadas IS 'Qué migración de supabase/migrations/ ya corrió en esta base. aplicada_en de las primeras 7 filas es la fecha del backfill, no la fecha real en que corrieron -esa no quedó registrada en ningún lado.';


--
-- Name: animal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animal (
    id_animal integer NOT NULL,
    id_estab_origen integer,
    id_raza integer,
    id_pelaje integer,
    id_cabana integer,
    id_madre integer,
    id_padre integer,
    sexo text NOT NULL,
    fecha_nacimiento date,
    fecha_nac_es_estimada boolean DEFAULT false NOT NULL,
    peso_nacer_kg numeric(5,2),
    origen text DEFAULT 'NACIDO'::text NOT NULL,
    fecha_ingreso date,
    activo boolean DEFAULT true NOT NULL,
    anio_nacimiento integer,
    anio_ingreso integer,
    anio_primer_servicio integer,
    padre_nombre text,
    observaciones text,
    CONSTRAINT animal_anio_ingreso_check CHECK (((anio_ingreso >= 1900) AND (anio_ingreso <= 2100))),
    CONSTRAINT animal_anio_nacimiento_check CHECK (((anio_nacimiento >= 1900) AND (anio_nacimiento <= 2100))),
    CONSTRAINT animal_anio_primer_servicio_check CHECK (((anio_primer_servicio >= 1900) AND (anio_primer_servicio <= 2100))),
    CONSTRAINT animal_check CHECK (((id_madre IS NULL) OR (id_madre <> id_animal))),
    CONSTRAINT animal_check1 CHECK (((id_padre IS NULL) OR (id_padre <> id_animal))),
    CONSTRAINT animal_origen_check CHECK ((origen = ANY (ARRAY['NACIDO'::text, 'COMPRADO'::text, 'RECIBIDO'::text]))),
    CONSTRAINT animal_peso_nacer_kg_check CHECK (((peso_nacer_kg IS NULL) OR ((peso_nacer_kg >= (10)::numeric) AND (peso_nacer_kg <= (70)::numeric)))),
    CONSTRAINT animal_sexo_check CHECK ((sexo = ANY (ARRAY['M'::text, 'H'::text])))
);


--
-- Name: TABLE animal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.animal IS 'Los nombres propios de toros (Apache, Pucara, Guamini...) se cargan aca como filas con sexo=''M'', para poder referenciarlos desde id_padre.';


--
-- Name: COLUMN animal.id_madre; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.animal.id_madre IS 'Confirmado: en animales HISTORICOS va a quedar NULL casi siempre (la genealogia del Excel es a nivel de categoria de la madre, no de individuo). Obligatorio completarlo de aqui en mas, en cada parto cargado por la app.';


--
-- Name: animal_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animal_categoria (
    id_animal_categoria integer NOT NULL,
    id_animal integer NOT NULL,
    id_categoria integer NOT NULL,
    fecha_desde date NOT NULL,
    fecha_hasta date,
    fecha_desde_es_estimada boolean DEFAULT false NOT NULL,
    CONSTRAINT animal_categoria_check CHECK (((fecha_hasta IS NULL) OR (fecha_hasta > fecha_desde)))
);


--
-- Name: animal_categoria_id_animal_categoria_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.animal_categoria ALTER COLUMN id_animal_categoria ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.animal_categoria_id_animal_categoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: animal_descarte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animal_descarte (
    id_animal_descarte integer NOT NULL,
    id_animal integer NOT NULL,
    id_motivo_descarte integer NOT NULL,
    id_trabajo integer,
    fecha_marca date NOT NULL,
    fecha_revocacion date,
    observacion text,
    CONSTRAINT animal_descarte_check CHECK (((fecha_revocacion IS NULL) OR (fecha_revocacion >= fecha_marca)))
);


--
-- Name: TABLE animal_descarte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.animal_descarte IS 'Marca de descarte sobre un animal VIVO. El "CUT" de las hojas Rodeo Gral. La salida real se sigue registrando en baja; esto es la decision previa.';


--
-- Name: animal_descarte_id_animal_descarte_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.animal_descarte ALTER COLUMN id_animal_descarte ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.animal_descarte_id_animal_descarte_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: animal_id_animal_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.animal ALTER COLUMN id_animal ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.animal_id_animal_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: animal_rodeo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animal_rodeo (
    id_animal_rodeo integer NOT NULL,
    id_animal integer NOT NULL,
    id_rodeo integer NOT NULL,
    fecha_desde date NOT NULL,
    fecha_hasta date,
    fecha_desde_es_estimada boolean DEFAULT false NOT NULL,
    CONSTRAINT animal_rodeo_check CHECK (((fecha_hasta IS NULL) OR (fecha_hasta > fecha_desde)))
);


--
-- Name: animal_rodeo_id_animal_rodeo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.animal_rodeo ALTER COLUMN id_animal_rodeo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.animal_rodeo_id_animal_rodeo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: animal_validacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animal_validacion (
    id_animal integer NOT NULL,
    estado text NOT NULL,
    id_persona integer,
    revisado_en timestamp with time zone DEFAULT now() NOT NULL,
    observacion text,
    CONSTRAINT animal_validacion_estado_check CHECK ((estado = ANY (ARRAY['VALIDADO'::text, 'CORREGIR'::text, 'DUDOSO'::text])))
);


--
-- Name: TABLE animal_validacion; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.animal_validacion IS 'Revision humana de los datos migrados del Excel. Sin fila = sin revisar. VALIDADO = los datos del animal estan bien. CORREGIR = tiene un error concreto, ver observacion. DUDOSO = no se puede decidir sin ver al animal.';


--
-- Name: baja; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.baja (
    id_baja integer NOT NULL,
    id_animal integer NOT NULL,
    id_causa_baja integer NOT NULL,
    id_trabajo integer,
    fecha date NOT NULL,
    peso_salida_kg numeric(6,2),
    destino text,
    dte_dtu text,
    observaciones text,
    id_persona_registro integer DEFAULT public.persona_actual(),
    fecha_es_estimada boolean DEFAULT false NOT NULL,
    CONSTRAINT baja_peso_salida_kg_check CHECK (((peso_salida_kg IS NULL) OR (peso_salida_kg > (0)::numeric)))
);


--
-- Name: TABLE baja; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.baja IS 'Confirmado: la app queda acotada a manejo fisico (kilos y cabezas). Sin precio_kg / moneda / comprador a proposito -- sin modulo economico.';


--
-- Name: COLUMN baja.id_persona_registro; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.baja.id_persona_registro IS 'Quien registro la baja. Igual que en evento: lo fuerza la base desde la sesion.';


--
-- Name: COLUMN baja.fecha_es_estimada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.baja.fecha_es_estimada IS 'true = la fecha de la baja NO es el día real en que el animal salió, sino el día en que se registró que ya no estaba. Es lo normal en las bajas de tipo REGULARIZACION. Cualquier cálculo de días que use baja.fecha tiene que excluir o marcar estas filas.';


--
-- Name: baja_id_baja_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.baja ALTER COLUMN id_baja ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.baja_id_baja_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cabana; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cabana (
    id_cabana integer NOT NULL,
    nombre text NOT NULL,
    contacto text
);


--
-- Name: cabana_id_cabana_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cabana ALTER COLUMN id_cabana ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.cabana_id_cabana_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    sexo text NOT NULL,
    orden integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT categoria_sexo_check CHECK ((sexo = ANY (ARRAY['M'::text, 'H'::text])))
);


--
-- Name: TABLE categoria; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.categoria IS 'Categorias productivas. La escala de hembras termina en CUT (cria de ultimo ternero), que es el ultimo ciclo antes de la baja.';


--
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.categoria ALTER COLUMN id_categoria ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categoria_id_categoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: causa_baja; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.causa_baja (
    id_causa_baja integer NOT NULL,
    tipo_baja text NOT NULL,
    descripcion text NOT NULL,
    CONSTRAINT causa_baja_tipo_baja_check CHECK ((tipo_baja = ANY (ARRAY['VENTA'::text, 'MUERTE'::text, 'TRASLADO'::text, 'FALTANTE'::text, 'REGULARIZACION'::text])))
);


--
-- Name: causa_baja_id_causa_baja_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.causa_baja ALTER COLUMN id_causa_baja ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.causa_baja_id_causa_baja_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: diagnostico_gestacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diagnostico_gestacion (
    id_evento integer NOT NULL,
    metodo text NOT NULL,
    resultado text NOT NULL,
    tamano text,
    edad_gestacional_dias integer,
    id_servicio integer,
    id_padre_probable integer,
    CONSTRAINT diagnostico_gestacion_check CHECK (((resultado <> 'VACIA'::text) OR ((tamano IS NULL) AND (edad_gestacional_dias IS NULL)))),
    CONSTRAINT diagnostico_gestacion_edad_gestacional_dias_check CHECK (((edad_gestacional_dias IS NULL) OR ((edad_gestacional_dias >= 20) AND (edad_gestacional_dias <= 290)))),
    CONSTRAINT diagnostico_gestacion_metodo_check CHECK ((metodo = ANY (ARRAY['TACTO'::text, 'ECOGRAFIA'::text]))),
    CONSTRAINT diagnostico_gestacion_resultado_check CHECK ((resultado = ANY (ARRAY['PRENADA'::text, 'VACIA'::text, 'DUDOSA'::text]))),
    CONSTRAINT diagnostico_gestacion_tamano_check CHECK (((tamano IS NULL) OR (tamano = ANY (ARRAY['CHICA'::text, 'MEDIANA'::text, 'GRANDE'::text]))))
);


--
-- Name: establecimiento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.establecimiento (
    id_establecimiento integer NOT NULL,
    cuig text NOT NULL,
    nombre text NOT NULL,
    es_propio boolean DEFAULT false NOT NULL,
    localidad text,
    provincia text,
    superficie_ha numeric(9,2),
    activo boolean DEFAULT true NOT NULL,
    CONSTRAINT establecimiento_superficie_ha_check CHECK (((superficie_ha IS NULL) OR (superficie_ha > (0)::numeric)))
);


--
-- Name: TABLE establecimiento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.establecimiento IS 'CUIG = establecimiento de ORIGEN del animal (confirmado con el productor). Solo Santa Ana es propio (es_propio=true); el resto son terceros de compra.';


--
-- Name: establecimiento_id_establecimiento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.establecimiento ALTER COLUMN id_establecimiento ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.establecimiento_id_establecimiento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento (
    id_evento integer NOT NULL,
    id_trabajo integer NOT NULL,
    id_animal integer NOT NULL,
    orden integer,
    comentario text,
    origen_dato text DEFAULT 'MANUAL'::text NOT NULL,
    audio_ref text,
    confianza numeric(3,2),
    validado boolean DEFAULT true NOT NULL,
    id_persona_registro integer DEFAULT public.persona_actual(),
    CONSTRAINT evento_confianza_check CHECK (((confianza IS NULL) OR ((confianza >= (0)::numeric) AND (confianza <= (1)::numeric)))),
    CONSTRAINT evento_origen_dato_check CHECK ((origen_dato = ANY (ARRAY['MANUAL'::text, 'RFID'::text, 'VOZ'::text, 'BALANZA'::text, 'IMPORTACION'::text])))
);


--
-- Name: COLUMN evento.id_persona_registro; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.evento.id_persona_registro IS 'Quien cargo este registro. Lo fuerza la base desde la sesion (auth.uid()) mediante el trigger trg_forzar_autoria_evento. NULL en los datos historicos migrados del Excel, donde esa informacion no existe.';


--
-- Name: evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.evento ALTER COLUMN id_evento ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.evento_id_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: evento_reproductivo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_reproductivo (
    id_evento integer NOT NULL,
    tipo text NOT NULL,
    id_servicio integer,
    id_padre_asignado integer,
    partida_semen text,
    nro_tubo text,
    protocolo text,
    id_inseminador integer,
    CONSTRAINT evento_reproductivo_tipo_check CHECK ((tipo = ANY (ARRAY['INSEMINACION'::text, 'CELO'::text, 'MONTA'::text, 'SINCRONIZACION'::text])))
);


--
-- Name: identificacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identificacion (
    id_identificacion integer NOT NULL,
    id_animal integer NOT NULL,
    id_tipo_ident integer NOT NULL,
    id_establecimiento integer,
    caravana text NOT NULL,
    fecha_alta date,
    fecha_baja date,
    motivo_baja text,
    fecha_alta_es_estimada boolean DEFAULT false NOT NULL,
    CONSTRAINT identificacion_check CHECK (((fecha_baja IS NULL) OR (fecha_baja >= fecha_alta)))
);


--
-- Name: TABLE identificacion; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.identificacion IS 'Confirmado: dentro de un mismo establecimiento un numero de caravana NUNCA se reutiliza. Por eso la unicidad de abajo es PERMANENTE.';


--
-- Name: COLUMN identificacion.fecha_alta; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.identificacion.fecha_alta IS 'Fecha de colocacion de la caravana. Null = desconocida (tipico en datos historicos migrados).';


--
-- Name: COLUMN identificacion.fecha_alta_es_estimada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.identificacion.fecha_alta_es_estimada IS 'true = la fecha es aproximada, no un dato real. Ver mig_pendiente para saber como se estimo.';


--
-- Name: identificacion_id_identificacion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.identificacion ALTER COLUMN id_identificacion ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.identificacion_id_identificacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: map_jornada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.map_jornada (
    id_jornada integer NOT NULL,
    hoja text NOT NULL,
    tabla_staging text NOT NULL,
    etiqueta_excel text NOT NULL,
    fecha date,
    tipo_trabajo text,
    confirmado boolean,
    nota text,
    registra_vacias boolean,
    prenez_lectura_dudosa boolean
);


--
-- Name: TABLE map_jornada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.map_jornada IS 'Jornadas de trabajo reconstruidas del Excel, con las banderas de confiabilidad. registra_vacias = false significa que el % de prenez de esa jornada no es interpretable.';


--
-- Name: COLUMN map_jornada.registra_vacias; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.map_jornada.registra_vacias IS 'false = la columna de origen nunca registro una vacia, asi que el % de prenez de esa jornada no es interpretable.';


--
-- Name: COLUMN map_jornada.prenez_lectura_dudosa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.map_jornada.prenez_lectura_dudosa IS 'true = el resultado de prenez de esta jornada depende de valores interpretados (map_prenez.confirmado = false).';


--
-- Name: map_jornada_col; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.map_jornada_col (
    id_jornada integer NOT NULL,
    col text NOT NULL,
    campo text NOT NULL,
    confirmado boolean,
    nota text,
    CONSTRAINT map_jornada_col_campo_check CHECK ((campo = ANY (ARRAY['PRENEZ'::text, 'CC'::text, 'DENTADURA'::text, 'TORO'::text, 'GNRH'::text, 'INSEMINADA'::text, 'COMENTARIO'::text, 'IGNORAR'::text])))
);


--
-- Name: map_jornada_id_jornada_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.map_jornada ALTER COLUMN id_jornada ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.map_jornada_id_jornada_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: medicion_corporal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medicion_corporal (
    id_evento integer NOT NULL,
    condicion_corporal numeric(3,2),
    dentadura text,
    alzada_cm numeric(5,1),
    CONSTRAINT medicion_corporal_alzada_cm_check CHECK (((alzada_cm IS NULL) OR ((alzada_cm >= (80)::numeric) AND (alzada_cm <= (180)::numeric)))),
    CONSTRAINT medicion_corporal_condicion_corporal_check CHECK (((condicion_corporal IS NULL) OR ((condicion_corporal >= (1)::numeric) AND (condicion_corporal <= (5)::numeric)))),
    CONSTRAINT medicion_corporal_dentadura_check CHECK (((dentadura IS NULL) OR (dentadura = ANY (ARRAY['2D'::text, '3D'::text, '4D'::text, '6D'::text, 'BLL'::text, '3/4D'::text, 'MD+'::text, 'MD'::text, 'MD-'::text, '1/4D'::text, '-1/4D'::text, 'SD/CUT'::text]))))
);


--
-- Name: COLUMN medicion_corporal.dentadura; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.medicion_corporal.dentadura IS 'Estado de dentadura. Escala ordenada: 2D < 3D < 4D < 6D < BLL (erupcion), luego 3/4D < MD+ < MD < MD- < 1/4D < SD/CUT (desgaste). Para agregar un valor hay que rehacer la restriccion: ver el bloque final de este archivo, que trae la plantilla lista.';


--
-- Name: mig_trabajo_jornada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mig_trabajo_jornada (
    id_trabajo integer NOT NULL,
    id_jornada integer NOT NULL
);


--
-- Name: motivo_descarte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.motivo_descarte (
    id_motivo_descarte integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    descripcion text
);


--
-- Name: TABLE motivo_descarte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.motivo_descarte IS 'Por que se decide que un animal sale. Distinto de causa_baja: causa_baja es como se fue (venta, muerte); esto es por que se decidio que se vaya.';


--
-- Name: motivo_descarte_id_motivo_descarte_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.motivo_descarte ALTER COLUMN id_motivo_descarte ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.motivo_descarte_id_motivo_descarte_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: parto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parto (
    id_parto integer NOT NULL,
    id_madre integer,
    id_cria integer,
    id_servicio integer,
    fecha date NOT NULL,
    dificultad text,
    resultado text DEFAULT 'VIVO'::text NOT NULL,
    CONSTRAINT parto_dificultad_check CHECK (((dificultad IS NULL) OR (dificultad = ANY (ARRAY['NORMAL'::text, 'ASISTIDO'::text, 'CESAREA'::text, 'DISTOCIA'::text])))),
    CONSTRAINT parto_resultado_check CHECK ((resultado = ANY (ARRAY['VIVO'::text, 'MUERTO'::text, 'ABORTO'::text])))
);


--
-- Name: parto_id_parto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.parto ALTER COLUMN id_parto ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.parto_id_parto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pelaje; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pelaje (
    id_pelaje integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL
);


--
-- Name: TABLE pelaje; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pelaje IS 'Separado de raza: resuelve valores mezclados tipo ''N C Car'' del Excel.';


--
-- Name: pelaje_id_pelaje_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pelaje ALTER COLUMN id_pelaje ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.pelaje_id_pelaje_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: persona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persona (
    id_persona integer NOT NULL,
    id_auth_user uuid,
    nombre text NOT NULL,
    rol text NOT NULL,
    usuario text,
    password_hash text,
    CONSTRAINT persona_rol_check CHECK ((rol = ANY (ARRAY['PROPIETARIO'::text, 'GESTOR'::text, 'GERENTE'::text, 'OPERATIVO'::text])))
);


--
-- Name: TABLE persona; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.persona IS 'id_auth_user vincula esta fila con el login real de Supabase Auth. Lo completa un PROPIETARIO/ENCARGADO la primera vez que alguien se registra (no lo asigna la propia persona, por seguridad).';


--
-- Name: COLUMN persona.usuario; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.persona.usuario IS 'Identificador de login, distinto de nombre. Único cuando no es null.';


--
-- Name: COLUMN persona.password_hash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.persona.password_hash IS 'Hash BCrypt de la contraseña. Lo valida Spring Security (ADR-001, Opción A1). Nunca texto plano, nunca se expone fuera del backend.';


--
-- Name: persona_id_persona_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.persona ALTER COLUMN id_persona ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.persona_id_persona_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pesaje; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pesaje (
    id_evento integer NOT NULL,
    peso_kg numeric(6,2) NOT NULL,
    tipo_pesada text,
    CONSTRAINT pesaje_peso_kg_check CHECK (((peso_kg >= (15)::numeric) AND (peso_kg <= (1400)::numeric))),
    CONSTRAINT pesaje_tipo_pesada_check CHECK ((tipo_pesada = ANY (ARRAY['NACIMIENTO'::text, 'DESTETE'::text, 'CONTROL'::text, 'ENTRADA'::text, 'SALIDA'::text, 'VENTA'::text])))
);


--
-- Name: potrero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.potrero (
    id_potrero integer NOT NULL,
    id_establecimiento integer NOT NULL,
    nombre text NOT NULL,
    superficie_ha numeric(9,2),
    recurso_forrajero text,
    CONSTRAINT potrero_superficie_ha_check CHECK (((superficie_ha IS NULL) OR (superficie_ha > (0)::numeric)))
);


--
-- Name: potrero_id_potrero_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.potrero ALTER COLUMN id_potrero ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.potrero_id_potrero_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: raza; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raza (
    id_raza integer NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    especie text DEFAULT 'Bovino'::text NOT NULL
);


--
-- Name: raza_id_raza_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.raza ALTER COLUMN id_raza ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.raza_id_raza_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: revision_toro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revision_toro (
    id_evento integer NOT NULL,
    apto boolean NOT NULL,
    circ_escrotal_cm numeric(4,1),
    aplomos text,
    resultado_raspaje text,
    motivo_rechazo text,
    CONSTRAINT revision_toro_aplomos_check CHECK (((aplomos IS NULL) OR (aplomos = ANY (ARRAY['BIEN'::text, 'REGULAR'::text, 'MAL'::text])))),
    CONSTRAINT revision_toro_circ_escrotal_cm_check CHECK (((circ_escrotal_cm IS NULL) OR ((circ_escrotal_cm >= (24)::numeric) AND (circ_escrotal_cm <= (50)::numeric)))),
    CONSTRAINT revision_toro_resultado_raspaje_check CHECK (((resultado_raspaje IS NULL) OR (resultado_raspaje = ANY (ARRAY['NEGATIVO'::text, 'TRICHOMONAS'::text, 'CAMPYLOBACTER'::text, 'SIN_RASPAR'::text]))))
);


--
-- Name: rodeo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rodeo (
    id_rodeo integer NOT NULL,
    id_establecimiento integer NOT NULL,
    nombre text NOT NULL,
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    orden integer NOT NULL
);


--
-- Name: rodeo_categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rodeo_categoria (
    id_rodeo_categoria integer NOT NULL,
    id_rodeo integer NOT NULL,
    id_categoria integer NOT NULL
);


--
-- Name: TABLE rodeo_categoria; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.rodeo_categoria IS 'Categorías admitidas por rodeo. Un id_rodeo sin ninguna fila acá = sin restricción de categoría (ej. Descarte, Tropa de Venta).';


--
-- Name: rodeo_categoria_id_rodeo_categoria_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rodeo_categoria_id_rodeo_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rodeo_categoria_id_rodeo_categoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rodeo_categoria_id_rodeo_categoria_seq OWNED BY public.rodeo_categoria.id_rodeo_categoria;


--
-- Name: rodeo_id_rodeo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.rodeo ALTER COLUMN id_rodeo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.rodeo_id_rodeo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sanidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sanidad (
    id_evento integer NOT NULL,
    producto text NOT NULL,
    principio_activo text,
    dosis numeric(8,2),
    unidad text,
    via text,
    lote_producto text,
    fecha_reingreso date,
    CONSTRAINT sanidad_via_check CHECK (((via IS NULL) OR (via = ANY (ARRAY['SC'::text, 'IM'::text, 'IV'::text, 'ORAL'::text, 'TOPICA'::text, 'INTRAMAMARIA'::text]))))
);


--
-- Name: servicio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicio (
    id_servicio integer NOT NULL,
    id_establecimiento integer NOT NULL,
    id_rodeo integer,
    campana text NOT NULL,
    tipo text NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    CONSTRAINT servicio_check CHECK (((fecha_fin IS NULL) OR (fecha_fin >= fecha_inicio))),
    CONSTRAINT servicio_tipo_check CHECK ((tipo = ANY (ARRAY['NATURAL'::text, 'IA'::text, 'IATF'::text, 'MIXTO'::text])))
);


--
-- Name: servicio_id_servicio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.servicio ALTER COLUMN id_servicio ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.servicio_id_servicio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: servicio_toro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicio_toro (
    id_servicio_toro integer NOT NULL,
    id_servicio integer NOT NULL,
    id_toro integer NOT NULL,
    fecha_entrada date NOT NULL,
    fecha_salida date,
    motivo_salida text
);


--
-- Name: servicio_toro_id_servicio_toro_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.servicio_toro ALTER COLUMN id_servicio_toro ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.servicio_toro_id_servicio_toro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tipo_identificacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_identificacion (
    id_tipo_ident integer NOT NULL,
    codigo text NOT NULL,
    descripcion text NOT NULL,
    ambito text NOT NULL,
    es_oficial boolean DEFAULT false NOT NULL,
    CONSTRAINT tipo_identificacion_ambito_check CHECK ((ambito = ANY (ARRAY['ESTABLECIMIENTO'::text, 'NACIONAL'::text])))
);


--
-- Name: tipo_identificacion_id_tipo_ident_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tipo_identificacion ALTER COLUMN id_tipo_ident ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.tipo_identificacion_id_tipo_ident_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: trabajo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trabajo (
    id_trabajo integer NOT NULL,
    id_establecimiento integer NOT NULL,
    id_responsable integer,
    fecha date NOT NULL,
    tipo_trabajo text NOT NULL,
    id_rodeo integer,
    observaciones text,
    CONSTRAINT trabajo_tipo_trabajo_check CHECK ((tipo_trabajo = ANY (ARRAY['TACTO'::text, 'ECOGRAFIA'::text, 'PESADA'::text, 'DESTETE'::text, 'IDENTIFICACION'::text, 'REVISION_TOROS'::text, 'INSEMINACION'::text, 'SANIDAD'::text, 'CLASIFICACION'::text, 'EMBARQUE'::text, 'OTRO'::text])))
);


--
-- Name: TABLE trabajo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.trabajo IS '"El paso por la manga" es la unidad natural de carga en campo.';


--
-- Name: trabajo_id_trabajo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.trabajo ALTER COLUMN id_trabajo ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.trabajo_id_trabajo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_adpv; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_adpv WITH (security_invoker='true') AS
 SELECT e.id_animal,
    t.fecha AS fecha_actual,
    p.peso_kg AS peso_actual,
    lag(t.fecha) OVER w AS fecha_previa,
    lag(p.peso_kg) OVER w AS peso_previo,
    round(((p.peso_kg - lag(p.peso_kg) OVER w) / (NULLIF((t.fecha - lag(t.fecha) OVER w), 0))::numeric), 3) AS adpv_kg_dia
   FROM ((public.evento e
     JOIN public.trabajo t ON ((t.id_trabajo = e.id_trabajo)))
     JOIN public.pesaje p ON ((p.id_evento = e.id_evento)))
  WINDOW w AS (PARTITION BY e.id_animal ORDER BY t.fecha);


--
-- Name: v_animal_a_descartar; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_animal_a_descartar WITH (security_invoker='true') AS
 SELECT a.id_animal,
    i.caravana AS identificacion,
    c.nombre AS categoria,
    md.nombre AS motivo,
    ad.fecha_marca,
    (CURRENT_DATE - ad.fecha_marca) AS dias_desde_la_marca,
    ad.observacion
   FROM (((((public.animal_descarte ad
     JOIN public.animal a ON ((a.id_animal = ad.id_animal)))
     JOIN public.motivo_descarte md ON ((md.id_motivo_descarte = ad.id_motivo_descarte)))
     LEFT JOIN public.identificacion i ON (((i.id_animal = a.id_animal) AND (i.fecha_baja IS NULL))))
     LEFT JOIN public.animal_categoria acat ON (((acat.id_animal = a.id_animal) AND (acat.fecha_hasta IS NULL))))
     LEFT JOIN public.categoria c ON ((c.id_categoria = acat.id_categoria)))
  WHERE ((ad.fecha_revocacion IS NULL) AND (NOT (EXISTS ( SELECT 1
           FROM public.baja b
          WHERE (b.id_animal = a.id_animal)))));


--
-- Name: VIEW v_animal_a_descartar; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_animal_a_descartar IS 'Marcados para salir y todavia en el campo. Es la lista para armar la venta.';


--
-- Name: v_animal_evento; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_animal_evento AS
 SELECT ev.id_evento,
    ev.id_animal,
    t.fecha,
    t.tipo_trabajo,
    t.observaciones AS jornada,
    est.cuig,
    ev.origen_dato,
    NULLIF(concat_ws(' · '::text,
        CASE
            WHEN (dg.id_evento IS NOT NULL) THEN ((('Tacto '::text || dg.resultado) || COALESCE(((' ('::text || dg.tamano) || ')'::text), ''::text)) || COALESCE(((' '::text || dg.edad_gestacional_dias) || ' dias'::text), ''::text))
            ELSE NULL::text
        END,
        CASE
            WHEN (rt.id_evento IS NOT NULL) THEN (('Revision '::text ||
            CASE
                WHEN rt.apto THEN 'apto'::text
                ELSE 'no apto'::text
            END) || COALESCE(((' ('::text || rt.circ_escrotal_cm) || ' cm)'::text), ''::text))
            ELSE NULL::text
        END,
        CASE
            WHEN (sa.id_evento IS NOT NULL) THEN (('Sanidad '::text || sa.producto) || COALESCE(((' ('::text || sa.dosis) || ')'::text), ''::text))
            ELSE NULL::text
        END,
        CASE
            WHEN (mc.condicion_corporal IS NOT NULL) THEN ('CC '::text || mc.condicion_corporal)
            ELSE NULL::text
        END,
        CASE
            WHEN (mc.dentadura IS NOT NULL) THEN ('dentadura '::text || mc.dentadura)
            ELSE NULL::text
        END,
        CASE
            WHEN (mc.alzada_cm IS NOT NULL) THEN (('alzada '::text || mc.alzada_cm) || ' cm'::text)
            ELSE NULL::text
        END,
        CASE
            WHEN (er.id_evento IS NOT NULL) THEN ((er.tipo || COALESCE((' tubo '::text || er.nro_tubo), ''::text)) || COALESCE((' partida '::text || er.partida_semen), ''::text))
            ELSE NULL::text
        END,
        CASE
            WHEN (pe.id_evento IS NOT NULL) THEN ((('Pesada '::text || pe.peso_kg) || ' kg'::text) || COALESCE(((' ('::text || pe.tipo_pesada) || ')'::text), ''::text))
            ELSE NULL::text
        END,
        CASE
            WHEN (t.tipo_trabajo = 'IDENTIFICACION'::text) THEN 'Identificacion'::text
            ELSE NULL::text
        END), ''::text) AS detalle,
        CASE
            WHEN (dg.id_evento IS NOT NULL) THEN 'TACTO'::text
            WHEN (rt.id_evento IS NOT NULL) THEN 'REVISION_TOROS'::text
            WHEN (sa.id_evento IS NOT NULL) THEN 'SANIDAD'::text
            WHEN (er.id_evento IS NOT NULL) THEN 'REPRODUCCION'::text
            WHEN (mc.id_evento IS NOT NULL) THEN 'CORPORAL'::text
            WHEN (pe.id_evento IS NOT NULL) THEN 'PESAJE'::text
            ELSE 'OTRO'::text
        END AS clase,
    dg.resultado AS tacto_resultado,
    mc.condicion_corporal,
    mc.dentadura,
    ev.comentario,
    rt.apto
   FROM ((((((((public.evento ev
     JOIN public.trabajo t ON ((t.id_trabajo = ev.id_trabajo)))
     LEFT JOIN public.establecimiento est ON ((est.id_establecimiento = t.id_establecimiento)))
     LEFT JOIN public.diagnostico_gestacion dg ON ((dg.id_evento = ev.id_evento)))
     LEFT JOIN public.medicion_corporal mc ON ((mc.id_evento = ev.id_evento)))
     LEFT JOIN public.evento_reproductivo er ON ((er.id_evento = ev.id_evento)))
     LEFT JOIN public.pesaje pe ON ((pe.id_evento = ev.id_evento)))
     LEFT JOIN public.revision_toro rt ON ((rt.id_evento = ev.id_evento)))
     LEFT JOIN public.sanidad sa ON ((sa.id_evento = ev.id_evento)));


--
-- Name: VIEW v_animal_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_animal_evento IS 'Linea de tiempo de un animal: tactos, estado corporal, reproduccion y pesadas aplanados en una sola forma. Filtrar por id_animal.';


--
-- Name: v_ident_principal; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_ident_principal WITH (security_invoker='true') AS
 SELECT DISTINCT ON (i.id_animal) i.id_animal,
    i.id_identificacion,
    i.caravana,
    i.id_tipo_ident,
    ti.codigo AS tipo_ident,
    i.id_establecimiento,
    i.fecha_alta,
    i.fecha_alta_es_estimada
   FROM (public.identificacion i
     JOIN public.tipo_identificacion ti USING (id_tipo_ident))
  WHERE (i.fecha_baja IS NULL)
  ORDER BY i.id_animal,
        CASE ti.codigo
            WHEN 'VISUAL'::text THEN 1
            WHEN 'RFID'::text THEN 2
            WHEN 'SENASA'::text THEN 3
            WHEN 'FUEGO'::text THEN 4
            ELSE 5
        END, i.id_identificacion;


--
-- Name: VIEW v_ident_principal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_ident_principal IS 'Una sola identificacion por animal, la que se usa para nombrarlo. Evita que un animal con varias identificaciones aparezca repetido en las listas.';


--
-- Name: v_animal_lista; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_animal_lista WITH (security_invoker='true') AS
 SELECT a.id_animal,
    vi.caravana,
    vi.tipo_ident,
    a.sexo,
    r.nombre AS raza,
    c.codigo AS categoria_codigo,
    c.nombre AS categoria,
    a.fecha_nacimiento,
    a.fecha_nac_es_estimada,
    vi.fecha_alta AS fecha_ident,
    vi.fecha_alta_es_estimada AS fecha_ident_es_estimada,
    e.cuig,
    a.activo,
    (b.id_baja IS NOT NULL) AS tiene_baja,
    COALESCE(v.estado, 'SIN_REVISAR'::text) AS validacion,
    v.observacion AS validacion_obs,
    v.revisado_en,
    p.nombre AS revisado_por,
    ( SELECT count(*) AS count
           FROM public.evento ev
          WHERE (ev.id_animal = a.id_animal)) AS eventos,
    (a.fecha_nacimiento IS NULL) AS sin_fecha_nac,
    (a.fecha_nac_es_estimada OR vi.fecha_alta_es_estimada) AS con_fecha_estimada,
    (c.id_categoria IS NULL) AS sin_categoria,
    rd.nombre AS rodeo,
    ar.fecha_desde AS en_rodeo_desde,
    ar.id_rodeo,
    c.id_categoria,
    pl.nombre AS pelaje,
    e.nombre AS establecimiento,
    a.anio_nacimiento,
    a.anio_ingreso,
    a.anio_primer_servicio,
    ar.fecha_desde_es_estimada AS en_rodeo_desde_es_estimada,
    a.peso_nacer_kg,
    a.id_padre,
    padre.caravana AS padre_caravana,
    a.padre_nombre,
    ( SELECT string_agg(i.caravana, ' · '::text ORDER BY
                CASE ti.codigo
                    WHEN 'VISUAL'::text THEN 1
                    WHEN 'FUEGO'::text THEN 2
                    WHEN 'ADICIONAL'::text THEN 3
                    WHEN 'RFID'::text THEN 4
                    WHEN 'SENASA'::text THEN 5
                    ELSE 6
                END, i.id_identificacion) AS string_agg
           FROM (public.identificacion i
             JOIN public.tipo_identificacion ti ON ((ti.id_tipo_ident = i.id_tipo_ident)))
          WHERE ((i.id_animal = a.id_animal) AND (i.fecha_baja IS NULL))) AS identificaciones,
    ac.fecha_desde AS categoria_desde,
    ac.fecha_desde_es_estimada AS categoria_desde_es_estimada,
    a.observaciones,
    r.codigo AS raza_codigo
   FROM ((((((((((((public.animal a
     LEFT JOIN public.v_ident_principal vi ON ((vi.id_animal = a.id_animal)))
     LEFT JOIN public.raza r ON ((r.id_raza = a.id_raza)))
     LEFT JOIN public.pelaje pl ON ((pl.id_pelaje = a.id_pelaje)))
     LEFT JOIN public.establecimiento e ON ((e.id_establecimiento = vi.id_establecimiento)))
     LEFT JOIN public.animal_categoria ac ON (((ac.id_animal = a.id_animal) AND (ac.fecha_hasta IS NULL))))
     LEFT JOIN public.categoria c ON ((c.id_categoria = ac.id_categoria)))
     LEFT JOIN public.animal_rodeo ar ON (((ar.id_animal = a.id_animal) AND (ar.fecha_hasta IS NULL))))
     LEFT JOIN public.rodeo rd ON ((rd.id_rodeo = ar.id_rodeo)))
     LEFT JOIN public.baja b ON ((b.id_animal = a.id_animal)))
     LEFT JOIN public.animal_validacion v ON ((v.id_animal = a.id_animal)))
     LEFT JOIN public.persona p ON ((p.id_persona = v.id_persona)))
     LEFT JOIN public.v_ident_principal padre ON ((padre.id_animal = a.id_padre)));


--
-- Name: v_animal_vigente; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_animal_vigente WITH (security_invoker='true') AS
 SELECT a.id_animal,
    e.cuig,
    iv.caravana,
    ir.caravana AS rfid,
    a.sexo,
    r.codigo AS raza,
    p.codigo AS pelaje,
    a.fecha_nacimiento,
    c.codigo AS categoria_actual,
    ro.nombre AS rodeo_actual,
    a.activo
   FROM (((((((((public.animal a
     LEFT JOIN public.establecimiento e ON ((e.id_establecimiento = a.id_estab_origen)))
     LEFT JOIN public.raza r ON ((r.id_raza = a.id_raza)))
     LEFT JOIN public.pelaje p ON ((p.id_pelaje = a.id_pelaje)))
     LEFT JOIN public.identificacion iv ON (((iv.id_animal = a.id_animal) AND (iv.fecha_baja IS NULL) AND (iv.id_tipo_ident = ( SELECT tipo_identificacion.id_tipo_ident
           FROM public.tipo_identificacion
          WHERE (tipo_identificacion.codigo = 'VISUAL'::text))))))
     LEFT JOIN public.identificacion ir ON (((ir.id_animal = a.id_animal) AND (ir.fecha_baja IS NULL) AND (ir.id_tipo_ident = ( SELECT tipo_identificacion.id_tipo_ident
           FROM public.tipo_identificacion
          WHERE (tipo_identificacion.codigo = 'RFID'::text))))))
     LEFT JOIN public.animal_categoria ac ON (((ac.id_animal = a.id_animal) AND (ac.fecha_hasta IS NULL))))
     LEFT JOIN public.categoria c ON ((c.id_categoria = ac.id_categoria)))
     LEFT JOIN public.animal_rodeo ar ON (((ar.id_animal = a.id_animal) AND (ar.fecha_hasta IS NULL))))
     LEFT JOIN public.rodeo ro ON ((ro.id_rodeo = ar.id_rodeo)));


--
-- Name: v_baja_resumen; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_baja_resumen WITH (security_invoker='true') AS
 SELECT cb.tipo_baja,
    cb.descripcion AS causa,
    count(*) AS animales,
    min(b.fecha) AS primera,
    max(b.fecha) AS ultima,
    count(*) FILTER (WHERE b.fecha_es_estimada) AS con_fecha_estimada,
    round(((100.0 * (count(*))::numeric) / (( SELECT count(*) AS count
           FROM public.animal))::numeric), 1) AS pct_del_padron
   FROM (public.baja b
     JOIN public.causa_baja cb USING (id_causa_baja))
  GROUP BY cb.tipo_baja, cb.descripcion;


--
-- Name: VIEW v_baja_resumen; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_baja_resumen IS 'Bajas por tipo y causa. Si REGULARIZACION supera el 10-15% del padrón, ese número hay que mostrarlo antes de que alguien lea los indicadores del primer año: significa que el Excel estaba bastante desactualizado.';


--
-- Name: v_carga_por_persona; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_carga_por_persona WITH (security_invoker='true') AS
 SELECT COALESCE(p.nombre, 'Historico migrado (sin autoria)'::text) AS persona,
    p.rol,
    t.tipo_trabajo,
    count(*) AS eventos,
    count(*) FILTER (WHERE (e.origen_dato = 'VOZ'::text)) AS por_voz,
    count(*) FILTER (WHERE (e.origen_dato = 'RFID'::text)) AS por_rfid,
    count(*) FILTER (WHERE (e.origen_dato = 'MANUAL'::text)) AS manual,
    count(*) FILTER (WHERE (NOT e.validado)) AS sin_validar,
    min(t.fecha) AS desde,
    max(t.fecha) AS hasta
   FROM ((public.evento e
     JOIN public.trabajo t USING (id_trabajo))
     LEFT JOIN public.persona p ON ((p.id_persona = e.id_persona_registro)))
  GROUP BY p.nombre, p.rol, t.tipo_trabajo;


--
-- Name: VIEW v_carga_por_persona; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_carga_por_persona IS 'Cuanto cargo cada persona y por que medio. Sirve para ver si la carga por voz genera mas datos sin validar que la manual, y para detectar quien necesita apoyo.';


--
-- Name: v_pendiente; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_pendiente WITH (security_invoker='true') AS
 SELECT id_pendiente,
    COALESCE(hoja, '(no se pudo ubicar)'::text) AS hoja_excel,
    fila_excel,
        CASE
            WHEN ((motivo ~~ 'DECISION MANUAL%'::text) OR (motivo ~~ 'LECTURA MIA%'::text) OR (motivo ~~ 'Fechas APROXIMADAS cargadas a pedido%'::text)) THEN '5 REGISTRO'::text
            WHEN ((motivo ~~ 'SIN DATO EN EL ORIGEN%'::text) OR (motivo ~~ 'Fila sin caravana%'::text) OR (motivo ~~ 'Autoria desconocida%'::text) OR (motivo ~~ 'Fila de seccion%'::text)) THEN '3 SIN DATO'::text
            WHEN ((motivo ~~ 'Dato sin lugar%'::text) OR (motivo ~~ 'Dato del Excel sin columna%'::text) OR (motivo ~~ 'Pesos NO migrados%'::text) OR (motivo ~~ 'Circunferencia escrotal%'::text) OR (motivo ~~ 'Revisiones 2024 y 2025%'::text) OR (motivo ~~ '%NO migrada%'::text) OR (motivo ~~ '%NO migradas%'::text) OR (motivo ~~ '%no se migro%'::text) OR (motivo ~~ '%no se migraron%'::text)) THEN '4 NO MIGRADO'::text
            WHEN ((motivo ~~ 'El %prenez%NO es interpretable%'::text) OR (motivo ~~ 'Condicion corporal con un solo valor%'::text) OR (motivo ~~ 'Caravana con espacio interno%'::text) OR (motivo ~~ 'Caravana pasada a mayusculas%'::text) OR (motivo ~~ 'Numero de identificacion sin el cero%'::text) OR (motivo ~~ 'Columnas corridas%'::text) OR (motivo ~~ 'NO MAPEAR%'::text) OR (motivo ~~ 'Filas 28 a 39%'::text)) THEN '2 AVISO DE CALIDAD'::text
            ELSE '1 ACCION TUYA'::text
        END AS clase,
        CASE
            WHEN (resuelto_en IS NULL) THEN 'abierto'::text
            ELSE 'resuelto'::text
        END AS estado,
    motivo,
    detalle,
    resuelto_en
   FROM stg.mig_pendiente p;


--
-- Name: VIEW v_pendiente; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_pendiente IS 'mig_pendiente clasificada. La clase importa mas que el total: solo la clase 1 espera una decision tuya.';


--
-- Name: v_pendiente_resumen; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_pendiente_resumen WITH (security_invoker='true') AS
 SELECT clase,
    motivo,
    count(*) AS filas,
    count(*) FILTER (WHERE (estado = 'abierto'::text)) AS abiertos,
    count(DISTINCT hoja_excel) AS hojas,
    string_agg(DISTINCT hoja_excel, ' · '::text ORDER BY hoja_excel) AS donde
   FROM public.v_pendiente
  GROUP BY clase, motivo;


--
-- Name: v_prenez_por_trabajo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_prenez_por_trabajo WITH (security_invoker='true') AS
 SELECT t.id_trabajo,
    t.fecha,
    ro.nombre AS rodeo,
    count(*) AS tactadas,
    sum(
        CASE
            WHEN (dg.resultado = 'PRENADA'::text) THEN 1
            ELSE 0
        END) AS prenadas,
    round(((100.0 * (sum(
        CASE
            WHEN (dg.resultado = 'PRENADA'::text) THEN 1
            ELSE 0
        END))::numeric) / (count(*))::numeric), 1) AS pct_prenez,
    sum(
        CASE
            WHEN (dg.tamano = 'GRANDE'::text) THEN 1
            ELSE 0
        END) AS cabeza_paricion
   FROM (((public.trabajo t
     JOIN public.evento e ON ((e.id_trabajo = t.id_trabajo)))
     JOIN public.diagnostico_gestacion dg ON ((dg.id_evento = e.id_evento)))
     LEFT JOIN public.rodeo ro ON ((ro.id_rodeo = t.id_rodeo)))
  GROUP BY t.id_trabajo, t.fecha, ro.nombre;


--
-- Name: v_qa_baja_sin_marca; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_baja_sin_marca WITH (security_invoker='true') AS
 SELECT b.id_baja,
    b.fecha,
    cb.tipo_baja,
    cb.descripcion,
    b.id_animal,
        CASE
            WHEN (EXISTS ( SELECT 1
               FROM public.animal_descarte ad
              WHERE (ad.id_animal = b.id_animal))) THEN 'tenia marca'::text
            ELSE 'sin marca previa'::text
        END AS marca
   FROM (public.baja b
     JOIN public.causa_baja cb ON ((cb.id_causa_baja = b.id_causa_baja)))
  WHERE (cb.tipo_baja = 'VENTA'::text);


--
-- Name: VIEW v_qa_baja_sin_marca; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_baja_sin_marca IS 'Ventas y si venian o no de una decision de descarte registrada. Muchas "sin marca previa" = las decisiones se toman fuera del sistema.';


--
-- Name: v_qa_carga_sospechosa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_carga_sospechosa WITH (security_invoker='true') AS
 SELECT COALESCE(p.nombre, 'Historico migrado'::text) AS persona,
    t.fecha,
    t.tipo_trabajo,
    count(*) AS eventos,
    count(*) FILTER (WHERE (m.condicion_corporal IS NOT NULL)) AS con_cc,
    round(avg(m.condicion_corporal), 2) AS cc_promedio,
    count(DISTINCT m.condicion_corporal) AS valores_cc_distintos
   FROM (((public.evento e
     JOIN public.trabajo t USING (id_trabajo))
     LEFT JOIN public.persona p ON ((p.id_persona = e.id_persona_registro)))
     LEFT JOIN public.medicion_corporal m ON ((m.id_evento = e.id_evento)))
  GROUP BY p.nombre, t.fecha, t.tipo_trabajo
 HAVING ((count(*) FILTER (WHERE (m.condicion_corporal IS NOT NULL)) >= 10) AND (count(DISTINCT m.condicion_corporal) <= 1));


--
-- Name: VIEW v_qa_carga_sospechosa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_carga_sospechosa IS 'Jornadas donde alguien cargo 10 o mas condiciones corporales y TODAS con el mismo valor. Es la firma de que se apreto siempre el mismo boton en lugar de medir. Este control no se podia hacer sin saber quien cargo cada dato.';


--
-- Name: v_qa_dentadura_retrocede; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_dentadura_retrocede WITH (security_invoker='true') AS
 WITH esc AS (
         SELECT m.id_evento,
            m.dentadura,
                CASE m.dentadura
                    WHEN '2D'::text THEN 1
                    WHEN '3D'::text THEN 2
                    WHEN '4D'::text THEN 3
                    WHEN '6D'::text THEN 4
                    WHEN 'BLL'::text THEN 5
                    WHEN '3/4D'::text THEN 6
                    WHEN 'MD+'::text THEN 7
                    WHEN 'MD'::text THEN 8
                    WHEN 'MD-'::text THEN 9
                    WHEN '1/4D'::text THEN 10
                    WHEN 'SD/CUT'::text THEN 11
                    ELSE NULL::integer
                END AS orden
           FROM public.medicion_corporal m
          WHERE (m.dentadura IS NOT NULL)
        ), hist AS (
         SELECT e.id_animal,
            t.fecha,
            esc.dentadura,
            esc.orden,
            lag(esc.orden) OVER (PARTITION BY e.id_animal ORDER BY t.fecha) AS orden_previo,
            lag(t.fecha) OVER (PARTITION BY e.id_animal ORDER BY t.fecha) AS fecha_previa,
            lag(esc.dentadura) OVER (PARTITION BY e.id_animal ORDER BY t.fecha) AS dentadura_previa
           FROM ((esc
             JOIN public.evento e USING (id_evento))
             JOIN public.trabajo t USING (id_trabajo))
        )
 SELECT h.id_animal,
    i.caravana,
    h.fecha_previa,
    h.dentadura_previa,
    h.fecha,
    h.dentadura,
    (h.orden_previo - h.orden) AS retroceso
   FROM (hist h
     LEFT JOIN public.identificacion i ON (((i.id_animal = h.id_animal) AND (i.id_tipo_ident = 1))))
  WHERE ((h.orden_previo IS NOT NULL) AND (h.orden < h.orden_previo));


--
-- Name: VIEW v_qa_dentadura_retrocede; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_dentadura_retrocede IS 'Animales cuya dentadura retrocedio en la escala entre dos jornadas. Es imposible biologicamente: siempre es un error de carga en una de las dos fechas.';


--
-- Name: v_qa_descarte_pendiente; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_descarte_pendiente WITH (security_invoker='true') AS
 SELECT id_animal,
    identificacion,
    categoria,
    motivo,
    fecha_marca,
    dias_desde_la_marca,
    observacion
   FROM public.v_animal_a_descartar
  WHERE (dias_desde_la_marca > 120)
  ORDER BY dias_desde_la_marca DESC;


--
-- Name: VIEW v_qa_descarte_pendiente; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_descarte_pendiente IS 'Marcados hace mas de 120 dias que siguen en el campo. Revisar.';


--
-- Name: v_qa_ident_duplicada; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_ident_duplicada WITH (security_invoker='true') AS
 SELECT identificacion.id_tipo_ident,
    identificacion.id_establecimiento,
    identificacion.caravana,
    count(*) AS veces
   FROM public.identificacion
  WHERE (identificacion.id_tipo_ident = ANY (ARRAY[1, 3, 5]))
  GROUP BY identificacion.id_tipo_ident, identificacion.id_establecimiento, identificacion.caravana
 HAVING (count(*) > 1)
UNION ALL
 SELECT identificacion.id_tipo_ident,
    NULL::integer AS id_establecimiento,
    identificacion.caravana,
    count(*) AS veces
   FROM public.identificacion
  WHERE (identificacion.id_tipo_ident = ANY (ARRAY[2, 4]))
  GROUP BY identificacion.id_tipo_ident, identificacion.caravana
 HAVING (count(*) > 1);


--
-- Name: v_qa_prenez_no_confiable; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_prenez_no_confiable WITH (security_invoker='true') AS
 SELECT t.id_trabajo,
    t.fecha,
    t.tipo_trabajo,
    mj.hoja,
    mj.etiqueta_excel,
    count(dg.*) AS diagnosticos,
    count(dg.*) FILTER (WHERE (dg.resultado = 'VACIA'::text)) AS vacias
   FROM ((((public.trabajo t
     JOIN public.mig_trabajo_jornada tj USING (id_trabajo))
     JOIN public.map_jornada mj USING (id_jornada))
     LEFT JOIN public.evento e ON ((e.id_trabajo = t.id_trabajo)))
     LEFT JOIN public.diagnostico_gestacion dg ON ((dg.id_evento = e.id_evento)))
  WHERE (mj.registra_vacias IS FALSE)
  GROUP BY t.id_trabajo, t.fecha, t.tipo_trabajo, mj.hoja, mj.etiqueta_excel;


--
-- Name: VIEW v_qa_prenez_no_confiable; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_prenez_no_confiable IS 'Trabajos cuyo % de prenez NO se puede interpretar: la planilla de origen no registraba vacias.';


--
-- Name: v_qa_regularizacion_sin_marca; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_regularizacion_sin_marca WITH (security_invoker='true') AS
 SELECT b.id_baja,
    b.id_animal,
    i.caravana,
    b.fecha,
    cb.descripcion AS causa,
    'Baja de regularizacion con fecha_es_estimada = false. Si la fecha real se conoce, la baja no deberia ser REGULARIZACION sino VENTA o MUERTE con esa fecha.'::text AS detalle
   FROM ((public.baja b
     JOIN public.causa_baja cb USING (id_causa_baja))
     LEFT JOIN public.v_ident_principal i ON ((i.id_animal = b.id_animal)))
  WHERE ((cb.tipo_baja = 'REGULARIZACION'::text) AND (NOT b.fecha_es_estimada));


--
-- Name: v_qa_regularizacion_tardia; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_regularizacion_tardia WITH (security_invoker='true') AS
 WITH arranque AS (
         SELECT min(b_1.fecha) AS desde
           FROM (public.baja b_1
             JOIN public.causa_baja cb_1 USING (id_causa_baja))
          WHERE (cb_1.tipo_baja = 'REGULARIZACION'::text)
        )
 SELECT b.id_baja,
    b.id_animal,
    i.caravana,
    b.fecha,
    cb.descripcion AS causa,
    (b.fecha - a.desde) AS dias_despues_del_arranque,
    'Baja de regularizacion cargada mucho despues del saneamiento. Revisar si no corresponde a una VENTA o MUERTE real.'::text AS detalle
   FROM (((public.baja b
     JOIN public.causa_baja cb USING (id_causa_baja))
     CROSS JOIN arranque a)
     LEFT JOIN public.v_ident_principal i ON ((i.id_animal = b.id_animal)))
  WHERE ((cb.tipo_baja = 'REGULARIZACION'::text) AND (b.fecha > (a.desde + 90)));


--
-- Name: v_qa_rodeo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_rodeo WITH (security_invoker='true') AS
 SELECT 'DOS RODEOS ABIERTOS'::text AS problema,
    animal_rodeo.id_animal,
    'El animal figura en mas de un rodeo a la vez. Cuenta doble en el stock.'::text AS detalle
   FROM public.animal_rodeo
  WHERE (animal_rodeo.fecha_hasta IS NULL)
  GROUP BY animal_rodeo.id_animal
 HAVING (count(*) > 1)
UNION ALL
 SELECT 'PERIODOS SUPERPUESTOS'::text AS problema,
    a.id_animal,
    ((('Estuvo en dos rodeos con fechas que se pisan: '::text || a.fecha_desde) || ' y '::text) || b.fecha_desde) AS detalle
   FROM (public.animal_rodeo a
     JOIN public.animal_rodeo b ON (((b.id_animal = a.id_animal) AND (b.id_animal_rodeo > a.id_animal_rodeo) AND (daterange(a.fecha_desde, a.fecha_hasta, '[)'::text) && daterange(b.fecha_desde, b.fecha_hasta, '[)'::text)))))
UNION ALL
 SELECT 'BAJA CON RODEO ABIERTO'::text AS problema,
    b.id_animal,
    (('El animal se dio de baja el '::text || b.fecha) || ' pero sigue figurando en un rodeo.'::text) AS detalle
   FROM (public.baja b
     JOIN public.animal_rodeo ar ON (((ar.id_animal = b.id_animal) AND (ar.fecha_hasta IS NULL))));


--
-- Name: v_qa_rodeo_categoria; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_rodeo_categoria WITH (security_invoker='true') AS
 SELECT ar.id_animal,
    i.caravana,
    rd.nombre AS rodeo,
    COALESCE(c.nombre, '(sin categoria)'::text) AS categoria_vigente,
    ar.fecha_desde AS en_el_rodeo_desde,
    (CURRENT_DATE - ar.fecha_desde) AS dias_en_el_rodeo
   FROM ((((public.animal_rodeo ar
     JOIN public.rodeo rd ON ((rd.id_rodeo = ar.id_rodeo)))
     LEFT JOIN public.animal_categoria ac ON (((ac.id_animal = ar.id_animal) AND (ac.fecha_hasta IS NULL))))
     LEFT JOIN public.categoria c ON ((c.id_categoria = ac.id_categoria)))
     LEFT JOIN public.v_ident_principal i ON ((i.id_animal = ar.id_animal)))
  WHERE ((ar.fecha_hasta IS NULL) AND (EXISTS ( SELECT 1
           FROM public.categoria c2
          WHERE (rd.nombre =
                CASE c2.codigo
                    WHEN 'CUT'::text THEN 'CUT'::text
                    ELSE c2.nombre
                END))) AND (rd.nombre IS DISTINCT FROM
        CASE c.codigo
            WHEN 'CUT'::text THEN 'CUT'::text
            ELSE c.nombre
        END));


--
-- Name: VIEW v_qa_rodeo_categoria; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_rodeo_categoria IS 'Animales que estan en un rodeo con nombre de categoria que NO coincide con su categoria vigente. No tiene que dar 0: puede haber razones para que un animal este ahi. Es un numero para mirar cada tanto, no una alarma.';


--
-- Name: v_qa_seguridad; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_seguridad WITH (security_invoker='true') AS
 SELECT 'TABLA SIN RLS'::text AS problema,
    (((ns.nspname)::text || '.'::text) || (c.relname)::text) AS objeto,
    ((('Cualquiera con la clave publicable puede leerla y escribirla. Corregir con: '::text || 'alter table '::text) || (c.relname)::text) || ' enable row level security;'::text) AS que_hacer
   FROM (pg_class c
     JOIN pg_namespace ns ON ((ns.oid = c.relnamespace)))
  WHERE ((c.relkind = 'r'::"char") AND (ns.nspname = ANY (ARRAY['public'::name, 'stg'::name])) AND (NOT c.relrowsecurity))
UNION ALL
 SELECT 'RLS ACTIVO SIN POLITICAS'::text AS problema,
    (((ns.nspname)::text || '.'::text) || (c.relname)::text) AS objeto,
        CASE
            WHEN (ns.nspname = 'stg'::name) THEN 'Intencional: el staging no se expone a la app.'::text
            ELSE ('Nadie puede leer ni escribir desde la app. Si no es lo buscado, '::text || 'faltan politicas.'::text)
        END AS que_hacer
   FROM (pg_class c
     JOIN pg_namespace ns ON ((ns.oid = c.relnamespace)))
  WHERE ((c.relkind = 'r'::"char") AND (ns.nspname = ANY (ARRAY['public'::name, 'stg'::name])) AND c.relrowsecurity AND (NOT (EXISTS ( SELECT 1
           FROM pg_policy p
          WHERE (p.polrelid = c.oid)))))
UNION ALL
 SELECT 'VISTA QUE ESQUIVA RLS'::text AS problema,
    (((ns.nspname)::text || '.'::text) || (c.relname)::text) AS objeto,
    ((('Se ejecuta con los privilegios de su dueno y saltea RLS. Corregir con: '::text || 'alter view '::text) || (c.relname)::text) || ' set (security_invoker = true);'::text) AS que_hacer
   FROM (pg_class c
     JOIN pg_namespace ns ON ((ns.oid = c.relnamespace)))
  WHERE ((c.relkind = 'v'::"char") AND (ns.nspname = ANY (ARRAY['public'::name, 'stg'::name])) AND (COALESCE(( SELECT pg_options_to_table.option_value
           FROM pg_options_to_table(c.reloptions) pg_options_to_table(option_name, option_value)
          WHERE (pg_options_to_table.option_name = 'security_invoker'::text)), 'false'::text) <> 'true'::text));


--
-- Name: VIEW v_qa_seguridad; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_seguridad IS 'Auditoria de seguridad. Tiene que devolver CERO filas, salvo las tablas stg_* que a proposito estan cerradas. Correrla cada vez que se agregue una tabla o una vista: es el control que evita reabrir el agujero de las vistas.';


--
-- Name: v_qa_seguridad_completa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_seguridad_completa WITH (security_invoker='true') AS
 SELECT n.nspname AS esquema,
    c.relname AS objeto,
        CASE c.relkind
            WHEN 'r'::"char" THEN 'tabla'::text
            WHEN 'v'::"char" THEN 'vista'::text
            ELSE (c.relkind)::text
        END AS tipo,
        CASE
            WHEN ((c.relkind = 'v'::"char") AND (NOT COALESCE(( SELECT (pg_options_to_table.option_value = 'true'::text)
               FROM pg_options_to_table(c.reloptions) pg_options_to_table(option_name, option_value)
              WHERE (pg_options_to_table.option_name = 'security_invoker'::text)), false))) THEN 'VISTA SIN security_invoker: saltea RLS'::text
            WHEN ((c.relkind = 'r'::"char") AND (NOT c.relrowsecurity)) THEN 'TABLA SIN row level security'::text
            ELSE 'ok'::text
        END AS problema,
        CASE
            WHEN (n.nspname = 'public'::name) THEN 'expuesto por la API'::text
            ELSE 'no expuesto por la API'::text
        END AS alcance
   FROM (pg_class c
     JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
  WHERE ((n.nspname = ANY (ARRAY['public'::name, 'stg'::name])) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char"])));


--
-- Name: VIEW v_qa_seguridad_completa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_qa_seguridad_completa IS 'Auditoria de seguridad sin puntos ciegos: mira public Y stg, tablas Y vistas. Reemplaza a la consulta del runbook, que excluia stg y por eso no encontro la vista v_qa_dentadura_retrocede mal ubicada.';


--
-- Name: v_qa_sin_categoria; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_qa_sin_categoria WITH (security_invoker='true') AS
 SELECT id_animal
   FROM public.animal a
  WHERE ((activo = true) AND (NOT (EXISTS ( SELECT 1
           FROM public.animal_categoria ac
          WHERE ((ac.id_animal = a.id_animal) AND (ac.fecha_hasta IS NULL))))));


--
-- Name: v_restricciones; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_restricciones WITH (security_invoker='true') AS
 WITH c AS (
         SELECT (rel.relname)::text AS tabla,
            (con.conname)::text AS restriccion,
            pg_get_constraintdef(con.oid) AS def
           FROM ((pg_constraint con
             JOIN pg_class rel ON ((rel.oid = con.conrelid)))
             JOIN pg_namespace n ON ((n.oid = rel.relnamespace)))
          WHERE ((n.nspname = 'public'::name) AND (con.contype = 'c'::"char"))
        )
 SELECT tabla,
    COALESCE((regexp_match(def, '\(?([a-z_]+)\)?(?:::text)? = ANY'::text))[1], (regexp_match(def, '\(\(?([a-z_]+)\)? >= '::text))[1], (regexp_match(def, '\(\(?([a-z_]+)\)? IS NULL'::text))[1]) AS columna,
        CASE
            WHEN (def ~~ '%= ANY (%'::text) THEN 'LISTA DE VALORES'::text
            WHEN ((def ~~ '%>=%'::text) AND (def ~~ '%<=%'::text)) THEN 'RANGO NUMERICO'::text
            ELSE 'OTRA REGLA'::text
        END AS tipo,
        CASE
            WHEN (def ~~ '%= ANY (%'::text) THEN ( SELECT string_agg(x.v, ' · '::text ORDER BY t.ord) AS string_agg
               FROM regexp_matches(c.def, '''([^'']+)''::text'::text, 'g'::text) WITH ORDINALITY t(m, ord),
                LATERAL ( SELECT t.m[1] AS v) x)
            WHEN ((def ~~ '%>=%'::text) AND (def ~~ '%<=%'::text)) THEN ((('de '::text || (regexp_match(def, '>= \(?([0-9.]+)'::text))[1]) || ' a '::text) || (regexp_match(def, '<= \(?([0-9.]+)'::text))[1])
            ELSE NULL::text
        END AS valores_permitidos,
    ( SELECT count(*) AS count
           FROM regexp_matches(c.def, '''[^'']+''::text'::text, 'g'::text) regexp_matches(regexp_matches)) AS cantidad,
        CASE
            WHEN ((tabla ~~ 'map_%'::text) OR (tabla ~~ 'mig_%'::text) OR (tabla ~~ 'stg_%'::text)) THEN 'MIGRACION'::text
            ELSE 'MODELO'::text
        END AS origen,
    restriccion,
    def AS definicion_completa
   FROM c;


--
-- Name: v_rodeo_actual; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_rodeo_actual WITH (security_invoker='true') AS
 SELECT a.id_animal,
    i.caravana,
    a.sexo,
    c.codigo AS categoria_codigo,
    c.nombre AS categoria,
    r.id_rodeo,
    r.nombre AS rodeo,
    ar.fecha_desde AS en_el_rodeo_desde,
    (CURRENT_DATE - ar.fecha_desde) AS dias_en_el_rodeo
   FROM (((((public.animal a
     LEFT JOIN public.v_ident_principal i ON ((i.id_animal = a.id_animal)))
     LEFT JOIN public.animal_rodeo ar ON (((ar.id_animal = a.id_animal) AND (ar.fecha_hasta IS NULL))))
     LEFT JOIN public.rodeo r ON ((r.id_rodeo = ar.id_rodeo)))
     LEFT JOIN public.animal_categoria ac ON (((ac.id_animal = a.id_animal) AND (ac.fecha_hasta IS NULL))))
     LEFT JOIN public.categoria c ON ((c.id_categoria = ac.id_categoria)))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public.baja b
          WHERE (b.id_animal = a.id_animal))));


--
-- Name: v_rodeo_composicion; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_rodeo_composicion WITH (security_invoker='true') AS
 SELECT COALESCE(rodeo, '(sin rodeo asignado)'::text) AS rodeo,
    COALESCE(categoria, '(sin categoria)'::text) AS categoria,
    count(*) AS cabezas,
    round(((100.0 * (count(*))::numeric) / sum(count(*)) OVER (PARTITION BY v_rodeo_actual.rodeo)), 1) AS pct_del_rodeo
   FROM public.v_rodeo_actual
  GROUP BY rodeo, categoria;


--
-- Name: VIEW v_rodeo_composicion; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_rodeo_composicion IS 'Que categorias hay dentro de cada rodeo y en que proporcion. Un rodeo puede tener una sola categoria o varias: esta vista muestra cual es el caso.';


--
-- Name: v_rodeo_movimientos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_rodeo_movimientos WITH (security_invoker='true') AS
 SELECT ar.id_animal,
    i.caravana,
    r.nombre AS rodeo,
    ar.fecha_desde,
    ar.fecha_hasta,
    (COALESCE(ar.fecha_hasta, CURRENT_DATE) - ar.fecha_desde) AS dias,
    (ar.fecha_hasta IS NULL) AS actual
   FROM ((public.animal_rodeo ar
     JOIN public.rodeo r ON ((r.id_rodeo = ar.id_rodeo)))
     LEFT JOIN public.v_ident_principal i ON ((i.id_animal = ar.id_animal)));


--
-- Name: v_rodeo_origen; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_rodeo_origen WITH (security_invoker='true') AS
 SELECT rd.nombre AS rodeo,
    COALESCE(e.cuig, '(sin establecimiento)'::text) AS cuig_origen,
    COALESCE(e.nombre, '—'::text) AS establecimiento_origen,
    count(*) AS cabezas,
    round(((100.0 * (count(*))::numeric) / sum(count(*)) OVER (PARTITION BY rd.nombre)), 1) AS pct_del_rodeo
   FROM (((public.animal_rodeo ar
     JOIN public.rodeo rd ON ((rd.id_rodeo = ar.id_rodeo)))
     LEFT JOIN public.v_ident_principal i ON ((i.id_animal = ar.id_animal)))
     LEFT JOIN public.establecimiento e ON ((e.id_establecimiento = i.id_establecimiento)))
  WHERE (ar.fecha_hasta IS NULL)
  GROUP BY rd.nombre, e.cuig, e.nombre;


--
-- Name: VIEW v_rodeo_origen; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_rodeo_origen IS 'De donde viene cada animal del rodeo, segun quien emitio su caravana. Que el origen no sea el establecimiento del rodeo es normal: son animales comprados. No es un error.';


--
-- Name: v_rodeo_stock; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_rodeo_stock WITH (security_invoker='true') AS
 SELECT COALESCE(rodeo, '(sin rodeo asignado)'::text) AS rodeo,
    count(*) AS cabezas,
    count(*) FILTER (WHERE (sexo = 'H'::text)) AS hembras,
    count(*) FILTER (WHERE (sexo = 'M'::text)) AS machos,
    count(DISTINCT categoria_codigo) AS categorias_distintas
   FROM public.v_rodeo_actual
  GROUP BY COALESCE(rodeo, '(sin rodeo asignado)'::text);


--
-- Name: v_stock_unificado; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_stock_unificado WITH (security_invoker='true') AS
 SELECT 'CATEGORIA'::text AS tipo,
    c.orden,
    c.nombre AS grupo,
    count(ac.id_animal) AS cabezas
   FROM (public.categoria c
     LEFT JOIN public.animal_categoria ac ON (((ac.id_categoria = c.id_categoria) AND (ac.fecha_hasta IS NULL))))
  GROUP BY c.orden, c.nombre
UNION ALL
 SELECT 'RODEO'::text AS tipo,
    (1000 + r.id_rodeo) AS orden,
    r.nombre AS grupo,
    count(ar.id_animal) AS cabezas
   FROM (public.rodeo r
     LEFT JOIN public.animal_rodeo ar ON (((ar.id_rodeo = r.id_rodeo) AND (ar.fecha_hasta IS NULL))))
  GROUP BY r.id_rodeo, r.nombre;


--
-- Name: VIEW v_stock_unificado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_stock_unificado IS 'Stock en un solo listado: categorias productivas y rodeos juntos, como se pidio verlo. Los rodeos NO son categorias en la base -cada animal conserva su categoria real- pero en el reporte aparecen en la misma lista.';


--
-- Name: v_validacion_avance; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_validacion_avance WITH (security_invoker='true') AS
 SELECT count(*) AS animales,
    count(v.id_animal) AS revisados,
    count(*) FILTER (WHERE (v.estado = 'VALIDADO'::text)) AS validados,
    count(*) FILTER (WHERE (v.estado = 'CORREGIR'::text)) AS a_corregir,
    count(*) FILTER (WHERE (v.estado = 'DUDOSO'::text)) AS dudosos,
    (count(*) - count(v.id_animal)) AS sin_revisar,
    round(((100.0 * (count(v.id_animal))::numeric) / (NULLIF(count(*), 0))::numeric), 1) AS pct_revisado
   FROM (public.animal a
     LEFT JOIN public.animal_validacion v ON ((v.id_animal = a.id_animal)));


--
-- Name: VIEW v_validacion_avance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_validacion_avance IS 'Avance de la revision post-migracion. Mientras dure esta etapa es el unico numero que hay que mirar.';


--
-- Name: rodeo_categoria id_rodeo_categoria; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo_categoria ALTER COLUMN id_rodeo_categoria SET DEFAULT nextval('public.rodeo_categoria_id_rodeo_categoria_seq'::regclass);


--
-- Name: _migraciones_aplicadas _migraciones_aplicadas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._migraciones_aplicadas
    ADD CONSTRAINT _migraciones_aplicadas_pkey PRIMARY KEY (version);


--
-- Name: animal_categoria animal_categoria_id_animal_fecha_desde_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_categoria
    ADD CONSTRAINT animal_categoria_id_animal_fecha_desde_key UNIQUE (id_animal, fecha_desde);


--
-- Name: animal_categoria animal_categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_categoria
    ADD CONSTRAINT animal_categoria_pkey PRIMARY KEY (id_animal_categoria);


--
-- Name: animal_descarte animal_descarte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_descarte
    ADD CONSTRAINT animal_descarte_pkey PRIMARY KEY (id_animal_descarte);


--
-- Name: animal animal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_pkey PRIMARY KEY (id_animal);


--
-- Name: animal_rodeo animal_rodeo_id_animal_fecha_desde_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_rodeo
    ADD CONSTRAINT animal_rodeo_id_animal_fecha_desde_key UNIQUE (id_animal, fecha_desde);


--
-- Name: animal_rodeo animal_rodeo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_rodeo
    ADD CONSTRAINT animal_rodeo_pkey PRIMARY KEY (id_animal_rodeo);


--
-- Name: animal_validacion animal_validacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_validacion
    ADD CONSTRAINT animal_validacion_pkey PRIMARY KEY (id_animal);


--
-- Name: baja baja_id_animal_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_id_animal_key UNIQUE (id_animal);


--
-- Name: baja baja_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_pkey PRIMARY KEY (id_baja);


--
-- Name: cabana cabana_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cabana
    ADD CONSTRAINT cabana_nombre_key UNIQUE (nombre);


--
-- Name: cabana cabana_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cabana
    ADD CONSTRAINT cabana_pkey PRIMARY KEY (id_cabana);


--
-- Name: categoria categoria_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_codigo_key UNIQUE (codigo);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- Name: causa_baja causa_baja_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.causa_baja
    ADD CONSTRAINT causa_baja_pkey PRIMARY KEY (id_causa_baja);


--
-- Name: causa_baja causa_baja_tipo_baja_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.causa_baja
    ADD CONSTRAINT causa_baja_tipo_baja_descripcion_key UNIQUE (tipo_baja, descripcion);


--
-- Name: diagnostico_gestacion diagnostico_gestacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diagnostico_gestacion
    ADD CONSTRAINT diagnostico_gestacion_pkey PRIMARY KEY (id_evento);


--
-- Name: establecimiento establecimiento_cuig_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimiento
    ADD CONSTRAINT establecimiento_cuig_key UNIQUE (cuig);


--
-- Name: establecimiento establecimiento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimiento
    ADD CONSTRAINT establecimiento_pkey PRIMARY KEY (id_establecimiento);


--
-- Name: evento evento_id_trabajo_id_animal_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_id_trabajo_id_animal_key UNIQUE (id_trabajo, id_animal);


--
-- Name: evento evento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_pkey PRIMARY KEY (id_evento);


--
-- Name: evento_reproductivo evento_reproductivo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reproductivo
    ADD CONSTRAINT evento_reproductivo_pkey PRIMARY KEY (id_evento);


--
-- Name: identificacion identificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identificacion
    ADD CONSTRAINT identificacion_pkey PRIMARY KEY (id_identificacion);


--
-- Name: map_jornada_col map_jornada_col_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_jornada_col
    ADD CONSTRAINT map_jornada_col_pkey PRIMARY KEY (id_jornada, col);


--
-- Name: map_jornada map_jornada_hoja_etiqueta_excel_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_jornada
    ADD CONSTRAINT map_jornada_hoja_etiqueta_excel_key UNIQUE (hoja, etiqueta_excel);


--
-- Name: map_jornada map_jornada_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_jornada
    ADD CONSTRAINT map_jornada_pkey PRIMARY KEY (id_jornada);


--
-- Name: medicion_corporal medicion_corporal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medicion_corporal
    ADD CONSTRAINT medicion_corporal_pkey PRIMARY KEY (id_evento);


--
-- Name: mig_trabajo_jornada mig_trabajo_jornada_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mig_trabajo_jornada
    ADD CONSTRAINT mig_trabajo_jornada_pkey PRIMARY KEY (id_trabajo);


--
-- Name: motivo_descarte motivo_descarte_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motivo_descarte
    ADD CONSTRAINT motivo_descarte_codigo_key UNIQUE (codigo);


--
-- Name: motivo_descarte motivo_descarte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motivo_descarte
    ADD CONSTRAINT motivo_descarte_pkey PRIMARY KEY (id_motivo_descarte);


--
-- Name: parto parto_id_cria_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parto
    ADD CONSTRAINT parto_id_cria_key UNIQUE (id_cria);


--
-- Name: parto parto_id_madre_fecha_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parto
    ADD CONSTRAINT parto_id_madre_fecha_key UNIQUE (id_madre, fecha);


--
-- Name: parto parto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parto
    ADD CONSTRAINT parto_pkey PRIMARY KEY (id_parto);


--
-- Name: pelaje pelaje_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pelaje
    ADD CONSTRAINT pelaje_codigo_key UNIQUE (codigo);


--
-- Name: pelaje pelaje_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pelaje
    ADD CONSTRAINT pelaje_pkey PRIMARY KEY (id_pelaje);


--
-- Name: persona persona_id_auth_user_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_id_auth_user_key UNIQUE (id_auth_user);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- Name: persona persona_usuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_usuario_key UNIQUE (usuario);


--
-- Name: pesaje pesaje_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pesaje
    ADD CONSTRAINT pesaje_pkey PRIMARY KEY (id_evento);


--
-- Name: potrero potrero_id_establecimiento_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.potrero
    ADD CONSTRAINT potrero_id_establecimiento_nombre_key UNIQUE (id_establecimiento, nombre);


--
-- Name: potrero potrero_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.potrero
    ADD CONSTRAINT potrero_pkey PRIMARY KEY (id_potrero);


--
-- Name: raza raza_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raza
    ADD CONSTRAINT raza_codigo_key UNIQUE (codigo);


--
-- Name: raza raza_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raza
    ADD CONSTRAINT raza_pkey PRIMARY KEY (id_raza);


--
-- Name: revision_toro revision_toro_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revision_toro
    ADD CONSTRAINT revision_toro_pkey PRIMARY KEY (id_evento);


--
-- Name: rodeo_categoria rodeo_categoria_id_rodeo_id_categoria_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo_categoria
    ADD CONSTRAINT rodeo_categoria_id_rodeo_id_categoria_key UNIQUE (id_rodeo, id_categoria);


--
-- Name: rodeo_categoria rodeo_categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo_categoria
    ADD CONSTRAINT rodeo_categoria_pkey PRIMARY KEY (id_rodeo_categoria);


--
-- Name: rodeo rodeo_id_establecimiento_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo
    ADD CONSTRAINT rodeo_id_establecimiento_nombre_key UNIQUE (id_establecimiento, nombre);


--
-- Name: rodeo rodeo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo
    ADD CONSTRAINT rodeo_pkey PRIMARY KEY (id_rodeo);


--
-- Name: sanidad sanidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sanidad
    ADD CONSTRAINT sanidad_pkey PRIMARY KEY (id_evento);


--
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id_servicio);


--
-- Name: servicio_toro servicio_toro_id_servicio_id_toro_fecha_entrada_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_toro
    ADD CONSTRAINT servicio_toro_id_servicio_id_toro_fecha_entrada_key UNIQUE (id_servicio, id_toro, fecha_entrada);


--
-- Name: servicio_toro servicio_toro_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_toro
    ADD CONSTRAINT servicio_toro_pkey PRIMARY KEY (id_servicio_toro);


--
-- Name: tipo_identificacion tipo_identificacion_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_identificacion
    ADD CONSTRAINT tipo_identificacion_codigo_key UNIQUE (codigo);


--
-- Name: tipo_identificacion tipo_identificacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_identificacion
    ADD CONSTRAINT tipo_identificacion_pkey PRIMARY KEY (id_tipo_ident);


--
-- Name: trabajo trabajo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_pkey PRIMARY KEY (id_trabajo);


--
-- Name: ix_animal_cat_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animal_cat_animal ON public.animal_categoria USING btree (id_animal, fecha_desde);


--
-- Name: ix_animal_descarte_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animal_descarte_fecha ON public.animal_descarte USING btree (fecha_marca);


--
-- Name: ix_animal_rodeo_anim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animal_rodeo_anim ON public.animal_rodeo USING btree (id_animal, fecha_desde);


--
-- Name: ix_animal_validacion_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_animal_validacion_estado ON public.animal_validacion USING btree (estado);


--
-- Name: ix_evento_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evento_animal ON public.evento USING btree (id_animal);


--
-- Name: ix_evento_trabajo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_evento_trabajo ON public.evento USING btree (id_trabajo);


--
-- Name: ix_ident_animal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ident_animal ON public.identificacion USING btree (id_animal);


--
-- Name: ix_ident_caravana; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ident_caravana ON public.identificacion USING btree (caravana);


--
-- Name: ix_parto_madre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_parto_madre ON public.parto USING btree (id_madre, fecha);


--
-- Name: ix_persona_auth_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_persona_auth_user ON public.persona USING btree (id_auth_user);


--
-- Name: ix_trabajo_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_trabajo_fecha ON public.trabajo USING btree (fecha);


--
-- Name: ux_animal_categoria_abierta; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_animal_categoria_abierta ON public.animal_categoria USING btree (id_animal) WHERE (fecha_hasta IS NULL);


--
-- Name: ux_animal_descarte_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_animal_descarte_vigente ON public.animal_descarte USING btree (id_animal) WHERE (fecha_revocacion IS NULL);


--
-- Name: ux_animal_rodeo_abierto; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_animal_rodeo_abierto ON public.animal_rodeo USING btree (id_animal) WHERE (fecha_hasta IS NULL);


--
-- Name: ux_ident_nacional; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ident_nacional ON public.identificacion USING btree (id_tipo_ident, caravana) WHERE (id_tipo_ident = ANY (ARRAY[2, 4]));


--
-- Name: ux_ident_visual_por_establecimiento; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ident_visual_por_establecimiento ON public.identificacion USING btree (id_establecimiento, caravana) WHERE (id_tipo_ident = 1);


--
-- Name: baja trg_forzar_autoria_baja; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_forzar_autoria_baja BEFORE INSERT OR UPDATE OF id_persona_registro ON public.baja FOR EACH ROW EXECUTE FUNCTION public.forzar_autoria();


--
-- Name: evento trg_forzar_autoria_evento; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_forzar_autoria_evento BEFORE INSERT OR UPDATE OF id_persona_registro ON public.evento FOR EACH ROW EXECUTE FUNCTION public.forzar_autoria();


--
-- Name: identificacion trg_ident_visual_requiere_establecimiento; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ident_visual_requiere_establecimiento AFTER INSERT ON public.identificacion FOR EACH ROW EXECUTE FUNCTION public.chk_identificacion_visual();


--
-- Name: animal_validacion trg_sellar_validacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sellar_validacion BEFORE INSERT OR UPDATE ON public.animal_validacion FOR EACH ROW EXECUTE FUNCTION public.sellar_validacion();


--
-- Name: animal_categoria animal_categoria_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_categoria
    ADD CONSTRAINT animal_categoria_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal) ON DELETE CASCADE;


--
-- Name: animal_categoria animal_categoria_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_categoria
    ADD CONSTRAINT animal_categoria_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria);


--
-- Name: animal_descarte animal_descarte_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_descarte
    ADD CONSTRAINT animal_descarte_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal) ON DELETE CASCADE;


--
-- Name: animal_descarte animal_descarte_id_motivo_descarte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_descarte
    ADD CONSTRAINT animal_descarte_id_motivo_descarte_fkey FOREIGN KEY (id_motivo_descarte) REFERENCES public.motivo_descarte(id_motivo_descarte);


--
-- Name: animal_descarte animal_descarte_id_trabajo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_descarte
    ADD CONSTRAINT animal_descarte_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES public.trabajo(id_trabajo);


--
-- Name: animal animal_id_cabana_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_id_cabana_fkey FOREIGN KEY (id_cabana) REFERENCES public.cabana(id_cabana);


--
-- Name: animal animal_id_estab_origen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_id_estab_origen_fkey FOREIGN KEY (id_estab_origen) REFERENCES public.establecimiento(id_establecimiento);


--
-- Name: animal animal_id_madre_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_id_madre_fkey FOREIGN KEY (id_madre) REFERENCES public.animal(id_animal);


--
-- Name: animal animal_id_padre_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_id_padre_fkey FOREIGN KEY (id_padre) REFERENCES public.animal(id_animal);


--
-- Name: animal animal_id_pelaje_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_id_pelaje_fkey FOREIGN KEY (id_pelaje) REFERENCES public.pelaje(id_pelaje);


--
-- Name: animal animal_id_raza_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal
    ADD CONSTRAINT animal_id_raza_fkey FOREIGN KEY (id_raza) REFERENCES public.raza(id_raza);


--
-- Name: animal_rodeo animal_rodeo_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_rodeo
    ADD CONSTRAINT animal_rodeo_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal) ON DELETE CASCADE;


--
-- Name: animal_rodeo animal_rodeo_id_rodeo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_rodeo
    ADD CONSTRAINT animal_rodeo_id_rodeo_fkey FOREIGN KEY (id_rodeo) REFERENCES public.rodeo(id_rodeo);


--
-- Name: animal_validacion animal_validacion_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_validacion
    ADD CONSTRAINT animal_validacion_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal) ON DELETE CASCADE;


--
-- Name: animal_validacion animal_validacion_id_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animal_validacion
    ADD CONSTRAINT animal_validacion_id_persona_fkey FOREIGN KEY (id_persona) REFERENCES public.persona(id_persona);


--
-- Name: baja baja_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal);


--
-- Name: baja baja_id_causa_baja_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_id_causa_baja_fkey FOREIGN KEY (id_causa_baja) REFERENCES public.causa_baja(id_causa_baja);


--
-- Name: baja baja_id_persona_registro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_id_persona_registro_fkey FOREIGN KEY (id_persona_registro) REFERENCES public.persona(id_persona);


--
-- Name: baja baja_id_trabajo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baja
    ADD CONSTRAINT baja_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES public.trabajo(id_trabajo);


--
-- Name: diagnostico_gestacion diagnostico_gestacion_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diagnostico_gestacion
    ADD CONSTRAINT diagnostico_gestacion_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: diagnostico_gestacion diagnostico_gestacion_id_padre_probable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diagnostico_gestacion
    ADD CONSTRAINT diagnostico_gestacion_id_padre_probable_fkey FOREIGN KEY (id_padre_probable) REFERENCES public.animal(id_animal);


--
-- Name: diagnostico_gestacion diagnostico_gestacion_id_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diagnostico_gestacion
    ADD CONSTRAINT diagnostico_gestacion_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicio(id_servicio);


--
-- Name: evento evento_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal);


--
-- Name: evento evento_id_persona_registro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_id_persona_registro_fkey FOREIGN KEY (id_persona_registro) REFERENCES public.persona(id_persona);


--
-- Name: evento evento_id_trabajo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento
    ADD CONSTRAINT evento_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES public.trabajo(id_trabajo) ON DELETE CASCADE;


--
-- Name: evento_reproductivo evento_reproductivo_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reproductivo
    ADD CONSTRAINT evento_reproductivo_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: evento_reproductivo evento_reproductivo_id_inseminador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reproductivo
    ADD CONSTRAINT evento_reproductivo_id_inseminador_fkey FOREIGN KEY (id_inseminador) REFERENCES public.persona(id_persona);


--
-- Name: evento_reproductivo evento_reproductivo_id_padre_asignado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reproductivo
    ADD CONSTRAINT evento_reproductivo_id_padre_asignado_fkey FOREIGN KEY (id_padre_asignado) REFERENCES public.animal(id_animal);


--
-- Name: evento_reproductivo evento_reproductivo_id_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reproductivo
    ADD CONSTRAINT evento_reproductivo_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicio(id_servicio);


--
-- Name: identificacion identificacion_id_animal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identificacion
    ADD CONSTRAINT identificacion_id_animal_fkey FOREIGN KEY (id_animal) REFERENCES public.animal(id_animal) ON DELETE CASCADE;


--
-- Name: identificacion identificacion_id_establecimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identificacion
    ADD CONSTRAINT identificacion_id_establecimiento_fkey FOREIGN KEY (id_establecimiento) REFERENCES public.establecimiento(id_establecimiento);


--
-- Name: identificacion identificacion_id_tipo_ident_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identificacion
    ADD CONSTRAINT identificacion_id_tipo_ident_fkey FOREIGN KEY (id_tipo_ident) REFERENCES public.tipo_identificacion(id_tipo_ident);


--
-- Name: map_jornada_col map_jornada_col_id_jornada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_jornada_col
    ADD CONSTRAINT map_jornada_col_id_jornada_fkey FOREIGN KEY (id_jornada) REFERENCES public.map_jornada(id_jornada) ON DELETE CASCADE;


--
-- Name: medicion_corporal medicion_corporal_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medicion_corporal
    ADD CONSTRAINT medicion_corporal_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: mig_trabajo_jornada mig_trabajo_jornada_id_jornada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mig_trabajo_jornada
    ADD CONSTRAINT mig_trabajo_jornada_id_jornada_fkey FOREIGN KEY (id_jornada) REFERENCES public.map_jornada(id_jornada);


--
-- Name: mig_trabajo_jornada mig_trabajo_jornada_id_trabajo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mig_trabajo_jornada
    ADD CONSTRAINT mig_trabajo_jornada_id_trabajo_fkey FOREIGN KEY (id_trabajo) REFERENCES public.trabajo(id_trabajo) ON DELETE CASCADE;


--
-- Name: parto parto_id_cria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parto
    ADD CONSTRAINT parto_id_cria_fkey FOREIGN KEY (id_cria) REFERENCES public.animal(id_animal);


--
-- Name: parto parto_id_madre_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parto
    ADD CONSTRAINT parto_id_madre_fkey FOREIGN KEY (id_madre) REFERENCES public.animal(id_animal);


--
-- Name: parto parto_id_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parto
    ADD CONSTRAINT parto_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicio(id_servicio);


--
-- Name: persona persona_id_auth_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_id_auth_user_fkey FOREIGN KEY (id_auth_user) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: pesaje pesaje_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pesaje
    ADD CONSTRAINT pesaje_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: potrero potrero_id_establecimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.potrero
    ADD CONSTRAINT potrero_id_establecimiento_fkey FOREIGN KEY (id_establecimiento) REFERENCES public.establecimiento(id_establecimiento);


--
-- Name: revision_toro revision_toro_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revision_toro
    ADD CONSTRAINT revision_toro_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: rodeo_categoria rodeo_categoria_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo_categoria
    ADD CONSTRAINT rodeo_categoria_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria);


--
-- Name: rodeo_categoria rodeo_categoria_id_rodeo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo_categoria
    ADD CONSTRAINT rodeo_categoria_id_rodeo_fkey FOREIGN KEY (id_rodeo) REFERENCES public.rodeo(id_rodeo);


--
-- Name: rodeo rodeo_id_establecimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rodeo
    ADD CONSTRAINT rodeo_id_establecimiento_fkey FOREIGN KEY (id_establecimiento) REFERENCES public.establecimiento(id_establecimiento);


--
-- Name: sanidad sanidad_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sanidad
    ADD CONSTRAINT sanidad_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.evento(id_evento) ON DELETE CASCADE;


--
-- Name: servicio servicio_id_establecimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_id_establecimiento_fkey FOREIGN KEY (id_establecimiento) REFERENCES public.establecimiento(id_establecimiento);


--
-- Name: servicio servicio_id_rodeo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_id_rodeo_fkey FOREIGN KEY (id_rodeo) REFERENCES public.rodeo(id_rodeo);


--
-- Name: servicio_toro servicio_toro_id_servicio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_toro
    ADD CONSTRAINT servicio_toro_id_servicio_fkey FOREIGN KEY (id_servicio) REFERENCES public.servicio(id_servicio) ON DELETE CASCADE;


--
-- Name: servicio_toro servicio_toro_id_toro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_toro
    ADD CONSTRAINT servicio_toro_id_toro_fkey FOREIGN KEY (id_toro) REFERENCES public.animal(id_animal);


--
-- Name: trabajo trabajo_id_establecimiento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_id_establecimiento_fkey FOREIGN KEY (id_establecimiento) REFERENCES public.establecimiento(id_establecimiento);


--
-- Name: trabajo trabajo_id_responsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_id_responsable_fkey FOREIGN KEY (id_responsable) REFERENCES public.persona(id_persona);


--
-- Name: trabajo trabajo_id_rodeo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trabajo
    ADD CONSTRAINT trabajo_id_rodeo_fkey FOREIGN KEY (id_rodeo) REFERENCES public.rodeo(id_rodeo);


--
-- Name: _migraciones_aplicadas; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public._migraciones_aplicadas ENABLE ROW LEVEL SECURITY;

--
-- Name: animal; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.animal ENABLE ROW LEVEL SECURITY;

--
-- Name: animal_categoria; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.animal_categoria ENABLE ROW LEVEL SECURITY;

--
-- Name: animal_categoria animal_categoria_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_categoria_delete_gestor ON public.animal_categoria FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: animal_categoria animal_categoria_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_categoria_insert_auth ON public.animal_categoria FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: animal_categoria animal_categoria_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_categoria_select_auth ON public.animal_categoria FOR SELECT TO authenticated USING (true);


--
-- Name: animal_categoria animal_categoria_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_categoria_update_auth ON public.animal_categoria FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: animal animal_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_delete_gestor ON public.animal FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: animal_descarte; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.animal_descarte ENABLE ROW LEVEL SECURITY;

--
-- Name: animal_descarte animal_descarte_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_descarte_delete_gestor ON public.animal_descarte FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: animal_descarte animal_descarte_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_descarte_insert_auth ON public.animal_descarte FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: animal_descarte animal_descarte_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_descarte_select_auth ON public.animal_descarte FOR SELECT TO authenticated USING (true);


--
-- Name: animal_descarte animal_descarte_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_descarte_update_auth ON public.animal_descarte FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: animal animal_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_insert_auth ON public.animal FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: animal_rodeo; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.animal_rodeo ENABLE ROW LEVEL SECURITY;

--
-- Name: animal_rodeo animal_rodeo_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_rodeo_delete_gestor ON public.animal_rodeo FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: animal_rodeo animal_rodeo_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_rodeo_insert_auth ON public.animal_rodeo FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: animal_rodeo animal_rodeo_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_rodeo_select_auth ON public.animal_rodeo FOR SELECT TO authenticated USING (true);


--
-- Name: animal_rodeo animal_rodeo_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_rodeo_update_auth ON public.animal_rodeo FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: animal animal_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_select_auth ON public.animal FOR SELECT TO authenticated USING (true);


--
-- Name: animal animal_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_update_auth ON public.animal FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: animal_validacion; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.animal_validacion ENABLE ROW LEVEL SECURITY;

--
-- Name: animal_validacion animal_validacion_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_validacion_delete_gestor ON public.animal_validacion FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: animal_validacion animal_validacion_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_validacion_insert_auth ON public.animal_validacion FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: animal_validacion animal_validacion_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_validacion_select_auth ON public.animal_validacion FOR SELECT TO authenticated USING (true);


--
-- Name: animal_validacion animal_validacion_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animal_validacion_update_auth ON public.animal_validacion FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: baja; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.baja ENABLE ROW LEVEL SECURITY;

--
-- Name: baja baja_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY baja_delete_gestor ON public.baja FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: baja baja_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY baja_insert_auth ON public.baja FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: baja baja_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY baja_select_auth ON public.baja FOR SELECT TO authenticated USING (true);


--
-- Name: baja baja_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY baja_update_gestor ON public.baja FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: cabana; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cabana ENABLE ROW LEVEL SECURITY;

--
-- Name: cabana cabana_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cabana_delete_gestor ON public.cabana FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: cabana cabana_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cabana_insert_gestor ON public.cabana FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: cabana cabana_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cabana_select_auth ON public.cabana FOR SELECT TO authenticated USING (true);


--
-- Name: cabana cabana_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cabana_update_gestor ON public.cabana FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: categoria; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.categoria ENABLE ROW LEVEL SECURITY;

--
-- Name: categoria categoria_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categoria_delete_gestor ON public.categoria FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: categoria categoria_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categoria_insert_gestor ON public.categoria FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: categoria categoria_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categoria_select_auth ON public.categoria FOR SELECT TO authenticated USING (true);


--
-- Name: categoria categoria_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categoria_update_gestor ON public.categoria FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: causa_baja; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.causa_baja ENABLE ROW LEVEL SECURITY;

--
-- Name: causa_baja causa_baja_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY causa_baja_delete_gestor ON public.causa_baja FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: causa_baja causa_baja_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY causa_baja_insert_gestor ON public.causa_baja FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: causa_baja causa_baja_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY causa_baja_select_auth ON public.causa_baja FOR SELECT TO authenticated USING (true);


--
-- Name: causa_baja causa_baja_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY causa_baja_update_gestor ON public.causa_baja FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: diagnostico_gestacion; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.diagnostico_gestacion ENABLE ROW LEVEL SECURITY;

--
-- Name: diagnostico_gestacion diagnostico_gestacion_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostico_gestacion_delete_gestor ON public.diagnostico_gestacion FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: diagnostico_gestacion diagnostico_gestacion_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostico_gestacion_insert_auth ON public.diagnostico_gestacion FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: diagnostico_gestacion diagnostico_gestacion_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostico_gestacion_select_auth ON public.diagnostico_gestacion FOR SELECT TO authenticated USING (true);


--
-- Name: diagnostico_gestacion diagnostico_gestacion_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostico_gestacion_update_auth ON public.diagnostico_gestacion FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: establecimiento; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.establecimiento ENABLE ROW LEVEL SECURITY;

--
-- Name: establecimiento establecimiento_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establecimiento_delete_gestor ON public.establecimiento FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: establecimiento establecimiento_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establecimiento_insert_gestor ON public.establecimiento FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: establecimiento establecimiento_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establecimiento_select_auth ON public.establecimiento FOR SELECT TO authenticated USING (true);


--
-- Name: establecimiento establecimiento_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establecimiento_update_gestor ON public.establecimiento FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: evento; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evento ENABLE ROW LEVEL SECURITY;

--
-- Name: evento evento_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_delete_gestor ON public.evento FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: evento evento_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_insert_auth ON public.evento FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: evento_reproductivo; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evento_reproductivo ENABLE ROW LEVEL SECURITY;

--
-- Name: evento_reproductivo evento_reproductivo_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_reproductivo_delete_gestor ON public.evento_reproductivo FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: evento_reproductivo evento_reproductivo_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_reproductivo_insert_auth ON public.evento_reproductivo FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: evento_reproductivo evento_reproductivo_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_reproductivo_select_auth ON public.evento_reproductivo FOR SELECT TO authenticated USING (true);


--
-- Name: evento_reproductivo evento_reproductivo_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_reproductivo_update_auth ON public.evento_reproductivo FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: evento evento_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_select_auth ON public.evento FOR SELECT TO authenticated USING (true);


--
-- Name: evento evento_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY evento_update_auth ON public.evento FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: identificacion; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.identificacion ENABLE ROW LEVEL SECURITY;

--
-- Name: identificacion identificacion_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY identificacion_delete_gestor ON public.identificacion FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: identificacion identificacion_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY identificacion_insert_auth ON public.identificacion FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: identificacion identificacion_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY identificacion_select_auth ON public.identificacion FOR SELECT TO authenticated USING (true);


--
-- Name: identificacion identificacion_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY identificacion_update_auth ON public.identificacion FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: map_jornada; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.map_jornada ENABLE ROW LEVEL SECURITY;

--
-- Name: map_jornada_col; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.map_jornada_col ENABLE ROW LEVEL SECURITY;

--
-- Name: map_jornada_col map_jornada_col_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY map_jornada_col_select_auth ON public.map_jornada_col FOR SELECT TO authenticated USING (true);


--
-- Name: map_jornada map_jornada_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY map_jornada_select_auth ON public.map_jornada FOR SELECT TO authenticated USING (true);


--
-- Name: map_jornada map_jornada_write_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY map_jornada_write_gestor ON public.map_jornada FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: medicion_corporal; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.medicion_corporal ENABLE ROW LEVEL SECURITY;

--
-- Name: medicion_corporal medicion_corporal_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY medicion_corporal_delete_gestor ON public.medicion_corporal FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: medicion_corporal medicion_corporal_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY medicion_corporal_insert_auth ON public.medicion_corporal FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: medicion_corporal medicion_corporal_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY medicion_corporal_select_auth ON public.medicion_corporal FOR SELECT TO authenticated USING (true);


--
-- Name: medicion_corporal medicion_corporal_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY medicion_corporal_update_auth ON public.medicion_corporal FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: mig_trabajo_jornada; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mig_trabajo_jornada ENABLE ROW LEVEL SECURITY;

--
-- Name: mig_trabajo_jornada mig_trabajo_jornada_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY mig_trabajo_jornada_select_auth ON public.mig_trabajo_jornada FOR SELECT TO authenticated USING (true);


--
-- Name: motivo_descarte; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.motivo_descarte ENABLE ROW LEVEL SECURITY;

--
-- Name: motivo_descarte motivo_descarte_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY motivo_descarte_delete_gestor ON public.motivo_descarte FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: motivo_descarte motivo_descarte_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY motivo_descarte_insert_gestor ON public.motivo_descarte FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: motivo_descarte motivo_descarte_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY motivo_descarte_select_auth ON public.motivo_descarte FOR SELECT TO authenticated USING (true);


--
-- Name: motivo_descarte motivo_descarte_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY motivo_descarte_update_gestor ON public.motivo_descarte FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: parto; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.parto ENABLE ROW LEVEL SECURITY;

--
-- Name: parto parto_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parto_delete_gestor ON public.parto FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: parto parto_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parto_insert_auth ON public.parto FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: parto parto_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parto_select_auth ON public.parto FOR SELECT TO authenticated USING (true);


--
-- Name: parto parto_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY parto_update_auth ON public.parto FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: pelaje; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pelaje ENABLE ROW LEVEL SECURITY;

--
-- Name: pelaje pelaje_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pelaje_delete_gestor ON public.pelaje FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: pelaje pelaje_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pelaje_insert_gestor ON public.pelaje FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: pelaje pelaje_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pelaje_select_auth ON public.pelaje FOR SELECT TO authenticated USING (true);


--
-- Name: pelaje pelaje_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pelaje_update_gestor ON public.pelaje FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: persona; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.persona ENABLE ROW LEVEL SECURITY;

--
-- Name: persona persona_delete_propietario; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY persona_delete_propietario ON public.persona FOR DELETE TO authenticated USING (public.es_propietario());


--
-- Name: persona persona_insert_propietario; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY persona_insert_propietario ON public.persona FOR INSERT TO authenticated WITH CHECK (public.es_propietario());


--
-- Name: persona persona_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY persona_select_auth ON public.persona FOR SELECT TO authenticated USING (true);


--
-- Name: persona persona_update_propietario; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY persona_update_propietario ON public.persona FOR UPDATE TO authenticated USING (public.es_propietario()) WITH CHECK (public.es_propietario());


--
-- Name: pesaje; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pesaje ENABLE ROW LEVEL SECURITY;

--
-- Name: pesaje pesaje_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pesaje_delete_gestor ON public.pesaje FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: pesaje pesaje_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pesaje_insert_auth ON public.pesaje FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: pesaje pesaje_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pesaje_select_auth ON public.pesaje FOR SELECT TO authenticated USING (true);


--
-- Name: pesaje pesaje_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pesaje_update_auth ON public.pesaje FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: potrero; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.potrero ENABLE ROW LEVEL SECURITY;

--
-- Name: potrero potrero_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY potrero_delete_gestor ON public.potrero FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: potrero potrero_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY potrero_insert_gestor ON public.potrero FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: potrero potrero_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY potrero_select_auth ON public.potrero FOR SELECT TO authenticated USING (true);


--
-- Name: potrero potrero_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY potrero_update_gestor ON public.potrero FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: raza; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.raza ENABLE ROW LEVEL SECURITY;

--
-- Name: raza raza_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY raza_delete_gestor ON public.raza FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: raza raza_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY raza_insert_gestor ON public.raza FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: raza raza_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY raza_select_auth ON public.raza FOR SELECT TO authenticated USING (true);


--
-- Name: raza raza_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY raza_update_gestor ON public.raza FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: revision_toro; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.revision_toro ENABLE ROW LEVEL SECURITY;

--
-- Name: revision_toro revision_toro_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY revision_toro_delete_gestor ON public.revision_toro FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: revision_toro revision_toro_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY revision_toro_insert_auth ON public.revision_toro FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: revision_toro revision_toro_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY revision_toro_select_auth ON public.revision_toro FOR SELECT TO authenticated USING (true);


--
-- Name: revision_toro revision_toro_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY revision_toro_update_auth ON public.revision_toro FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: rodeo; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.rodeo ENABLE ROW LEVEL SECURITY;

--
-- Name: rodeo_categoria; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.rodeo_categoria ENABLE ROW LEVEL SECURITY;

--
-- Name: rodeo rodeo_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rodeo_delete_gestor ON public.rodeo FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: rodeo rodeo_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rodeo_insert_gestor ON public.rodeo FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: rodeo rodeo_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rodeo_select_auth ON public.rodeo FOR SELECT TO authenticated USING (true);


--
-- Name: rodeo rodeo_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rodeo_update_gestor ON public.rodeo FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: sanidad; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sanidad ENABLE ROW LEVEL SECURITY;

--
-- Name: sanidad sanidad_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sanidad_delete_gestor ON public.sanidad FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: sanidad sanidad_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sanidad_insert_auth ON public.sanidad FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: sanidad sanidad_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sanidad_select_auth ON public.sanidad FOR SELECT TO authenticated USING (true);


--
-- Name: sanidad sanidad_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sanidad_update_auth ON public.sanidad FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: servicio; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.servicio ENABLE ROW LEVEL SECURITY;

--
-- Name: servicio servicio_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_delete_gestor ON public.servicio FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: servicio servicio_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_insert_auth ON public.servicio FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: servicio servicio_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_select_auth ON public.servicio FOR SELECT TO authenticated USING (true);


--
-- Name: servicio_toro; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.servicio_toro ENABLE ROW LEVEL SECURITY;

--
-- Name: servicio_toro servicio_toro_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_toro_delete_gestor ON public.servicio_toro FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: servicio_toro servicio_toro_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_toro_insert_auth ON public.servicio_toro FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: servicio_toro servicio_toro_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_toro_select_auth ON public.servicio_toro FOR SELECT TO authenticated USING (true);


--
-- Name: servicio_toro servicio_toro_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_toro_update_auth ON public.servicio_toro FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: servicio servicio_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY servicio_update_auth ON public.servicio FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: tipo_identificacion; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tipo_identificacion ENABLE ROW LEVEL SECURITY;

--
-- Name: tipo_identificacion tipo_identificacion_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tipo_identificacion_delete_gestor ON public.tipo_identificacion FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: tipo_identificacion tipo_identificacion_insert_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tipo_identificacion_insert_gestor ON public.tipo_identificacion FOR INSERT TO authenticated WITH CHECK (public.es_gestor());


--
-- Name: tipo_identificacion tipo_identificacion_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tipo_identificacion_select_auth ON public.tipo_identificacion FOR SELECT TO authenticated USING (true);


--
-- Name: tipo_identificacion tipo_identificacion_update_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tipo_identificacion_update_gestor ON public.tipo_identificacion FOR UPDATE TO authenticated USING (public.es_gestor()) WITH CHECK (public.es_gestor());


--
-- Name: trabajo; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.trabajo ENABLE ROW LEVEL SECURITY;

--
-- Name: trabajo trabajo_delete_gestor; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trabajo_delete_gestor ON public.trabajo FOR DELETE TO authenticated USING (public.es_gestor());


--
-- Name: trabajo trabajo_insert_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trabajo_insert_auth ON public.trabajo FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: trabajo trabajo_select_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trabajo_select_auth ON public.trabajo FOR SELECT TO authenticated USING (true);


--
-- Name: trabajo trabajo_update_auth; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trabajo_update_auth ON public.trabajo FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- PostgreSQL database dump complete
--


