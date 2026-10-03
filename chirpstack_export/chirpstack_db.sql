--
-- PostgreSQL database dump
--

\restrict zLwlg6CQuCz5edpt6ZMfQTdTNRoLGA9xf4IuSUn5EsZe71vsF9Br8yZiztlI2Dm

-- Dumped from database version 17.10 (Debian 17.10-0+deb13u1)
-- Dumped by pg_dump version 17.10 (Debian 17.10-0+deb13u1)

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
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO chirpstack;

--
-- Name: api_key; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.api_key (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    is_admin boolean NOT NULL,
    tenant_id uuid,
    is_read_only boolean NOT NULL
);


ALTER TABLE public.api_key OWNER TO chirpstack;

--
-- Name: application; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.application (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    mqtt_tls_cert bytea,
    tags jsonb NOT NULL
);


ALTER TABLE public.application OWNER TO chirpstack;

--
-- Name: application_integration; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.application_integration (
    application_id uuid NOT NULL,
    kind character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    configuration jsonb NOT NULL
);


ALTER TABLE public.application_integration OWNER TO chirpstack;

--
-- Name: device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device (
    dev_eui bytea NOT NULL,
    application_id uuid NOT NULL,
    device_profile_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_seen_at timestamp with time zone,
    scheduler_run_after timestamp with time zone,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    external_power_source boolean NOT NULL,
    battery_level numeric(5,2),
    margin integer,
    dr smallint,
    latitude double precision,
    longitude double precision,
    altitude real,
    dev_addr bytea,
    enabled_class character(1) NOT NULL,
    skip_fcnt_check boolean NOT NULL,
    is_disabled boolean NOT NULL,
    tags jsonb NOT NULL,
    variables jsonb NOT NULL,
    join_eui bytea NOT NULL,
    secondary_dev_addr bytea,
    device_session bytea,
    app_layer_params jsonb NOT NULL,
    f_cnt_up bigint NOT NULL
);


ALTER TABLE public.device OWNER TO chirpstack;

--
-- Name: device_keys; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_keys (
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    nwk_key bytea NOT NULL,
    app_key bytea NOT NULL,
    dev_nonces jsonb NOT NULL,
    join_nonce integer NOT NULL,
    gen_app_key bytea NOT NULL
);


ALTER TABLE public.device_keys OWNER TO chirpstack;

--
-- Name: device_profile; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile (
    id uuid NOT NULL,
    tenant_id uuid,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    region character varying(10) NOT NULL,
    mac_version character varying(10) NOT NULL,
    reg_params_revision character varying(20) NOT NULL,
    adr_algorithm_id character varying(100) NOT NULL,
    payload_codec_runtime character varying(20) NOT NULL,
    uplink_interval integer NOT NULL,
    device_status_req_interval integer NOT NULL,
    supports_otaa boolean NOT NULL,
    supports_class_b boolean NOT NULL,
    supports_class_c boolean NOT NULL,
    tags jsonb NOT NULL,
    payload_codec_script text NOT NULL,
    flush_queue_on_activate boolean NOT NULL,
    description text NOT NULL,
    measurements jsonb NOT NULL,
    auto_detect_measurements boolean NOT NULL,
    region_config_id character varying(100),
    allow_roaming boolean NOT NULL,
    rx1_delay smallint NOT NULL,
    abp_params jsonb,
    class_b_params jsonb,
    class_c_params jsonb,
    relay_params jsonb,
    app_layer_params jsonb NOT NULL,
    device_id uuid,
    firmware_version character varying(20) NOT NULL,
    vendor_profile_id integer NOT NULL,
    supported_uplink_data_rates smallint[] NOT NULL
);


ALTER TABLE public.device_profile OWNER TO chirpstack;

--
-- Name: device_profile_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile_device (
    id uuid NOT NULL,
    vendor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    metadata jsonb NOT NULL
);


ALTER TABLE public.device_profile_device OWNER TO chirpstack;

--
-- Name: device_profile_template; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile_template (
    id text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    vendor character varying(100) NOT NULL,
    firmware character varying(100) NOT NULL,
    region character varying(10) NOT NULL,
    mac_version character varying(10) NOT NULL,
    reg_params_revision character varying(20) NOT NULL,
    adr_algorithm_id character varying(100) NOT NULL,
    payload_codec_runtime character varying(20) NOT NULL,
    payload_codec_script text NOT NULL,
    uplink_interval integer NOT NULL,
    device_status_req_interval integer NOT NULL,
    flush_queue_on_activate boolean NOT NULL,
    supports_otaa boolean NOT NULL,
    supports_class_b boolean NOT NULL,
    supports_class_c boolean NOT NULL,
    class_b_timeout integer NOT NULL,
    class_b_ping_slot_periodicity integer NOT NULL,
    class_b_ping_slot_dr smallint NOT NULL,
    class_b_ping_slot_freq bigint NOT NULL,
    class_c_timeout integer NOT NULL,
    abp_rx1_delay smallint NOT NULL,
    abp_rx1_dr_offset smallint NOT NULL,
    abp_rx2_dr smallint NOT NULL,
    abp_rx2_freq bigint NOT NULL,
    tags jsonb NOT NULL,
    measurements jsonb NOT NULL,
    auto_detect_measurements boolean NOT NULL
);


ALTER TABLE public.device_profile_template OWNER TO chirpstack;

--
-- Name: device_profile_vendor; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_profile_vendor (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name text NOT NULL,
    vendor_id integer NOT NULL,
    ouis text[] NOT NULL,
    metadata jsonb NOT NULL
);


ALTER TABLE public.device_profile_vendor OWNER TO chirpstack;

--
-- Name: device_queue_item; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.device_queue_item (
    id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    f_port smallint NOT NULL,
    confirmed boolean NOT NULL,
    data bytea NOT NULL,
    is_pending boolean NOT NULL,
    f_cnt_down bigint,
    timeout_after timestamp with time zone,
    is_encrypted boolean NOT NULL,
    expires_at timestamp with time zone
);


ALTER TABLE public.device_queue_item OWNER TO chirpstack;

--
-- Name: fuota_deployment; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    name character varying(100) NOT NULL,
    application_id uuid NOT NULL,
    device_profile_id uuid NOT NULL,
    multicast_addr bytea NOT NULL,
    multicast_key bytea NOT NULL,
    multicast_group_type character(1) NOT NULL,
    multicast_class_c_scheduling_type character varying(20) NOT NULL,
    multicast_dr smallint NOT NULL,
    multicast_class_b_ping_slot_periodicity smallint NOT NULL,
    multicast_frequency bigint NOT NULL,
    multicast_timeout smallint NOT NULL,
    multicast_session_start timestamp with time zone,
    multicast_session_end timestamp with time zone,
    unicast_max_retry_count smallint NOT NULL,
    fragmentation_fragment_size smallint NOT NULL,
    fragmentation_redundancy_percentage smallint NOT NULL,
    fragmentation_session_index smallint NOT NULL,
    fragmentation_matrix smallint NOT NULL,
    fragmentation_block_ack_delay smallint NOT NULL,
    fragmentation_descriptor bytea NOT NULL,
    request_fragmentation_session_status character varying(20) NOT NULL,
    payload bytea NOT NULL,
    on_complete_set_device_tags jsonb NOT NULL
);


ALTER TABLE public.fuota_deployment OWNER TO chirpstack;

--
-- Name: fuota_deployment_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_device (
    fuota_deployment_id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    mc_group_setup_completed_at timestamp with time zone,
    mc_session_completed_at timestamp with time zone,
    frag_session_setup_completed_at timestamp with time zone,
    frag_status_completed_at timestamp with time zone,
    error_msg text NOT NULL
);


ALTER TABLE public.fuota_deployment_device OWNER TO chirpstack;

--
-- Name: fuota_deployment_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_gateway (
    fuota_deployment_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.fuota_deployment_gateway OWNER TO chirpstack;

--
-- Name: fuota_deployment_job; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.fuota_deployment_job (
    fuota_deployment_id uuid NOT NULL,
    job character varying(20) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    max_retry_count smallint NOT NULL,
    attempt_count smallint NOT NULL,
    scheduler_run_after timestamp with time zone NOT NULL,
    warning_msg text NOT NULL,
    error_msg text NOT NULL
);


ALTER TABLE public.fuota_deployment_job OWNER TO chirpstack;

--
-- Name: gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.gateway (
    gateway_id bytea NOT NULL,
    tenant_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_seen_at timestamp with time zone,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    altitude real NOT NULL,
    stats_interval_secs integer NOT NULL,
    tls_certificate bytea,
    tags jsonb NOT NULL,
    properties jsonb NOT NULL
);


ALTER TABLE public.gateway OWNER TO chirpstack;

--
-- Name: multicast_group; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group (
    id uuid NOT NULL,
    application_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    region character varying(10) NOT NULL,
    mc_addr bytea NOT NULL,
    mc_nwk_s_key bytea NOT NULL,
    mc_app_s_key bytea NOT NULL,
    f_cnt bigint NOT NULL,
    group_type character(1) NOT NULL,
    dr smallint NOT NULL,
    frequency bigint NOT NULL,
    class_b_ping_slot_periodicity smallint NOT NULL,
    class_c_scheduling_type character varying(20) NOT NULL
);


ALTER TABLE public.multicast_group OWNER TO chirpstack;

--
-- Name: multicast_group_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_device (
    multicast_group_id uuid NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.multicast_group_device OWNER TO chirpstack;

--
-- Name: multicast_group_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_gateway (
    multicast_group_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.multicast_group_gateway OWNER TO chirpstack;

--
-- Name: multicast_group_queue_item; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.multicast_group_queue_item (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    scheduler_run_after timestamp with time zone NOT NULL,
    multicast_group_id uuid NOT NULL,
    gateway_id bytea NOT NULL,
    f_cnt bigint NOT NULL,
    f_port smallint NOT NULL,
    data bytea NOT NULL,
    emit_at_time_since_gps_epoch bigint,
    expires_at timestamp with time zone
);


ALTER TABLE public.multicast_group_queue_item OWNER TO chirpstack;

--
-- Name: relay_device; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.relay_device (
    relay_dev_eui bytea NOT NULL,
    dev_eui bytea NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.relay_device OWNER TO chirpstack;

--
-- Name: relay_gateway; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.relay_gateway (
    tenant_id uuid NOT NULL,
    relay_id bytea NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    last_seen_at timestamp with time zone,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    stats_interval_secs integer NOT NULL,
    region_config_id character varying(100) NOT NULL
);


ALTER TABLE public.relay_gateway OWNER TO chirpstack;

--
-- Name: tenant; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.tenant (
    id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    name character varying(100) NOT NULL,
    description text NOT NULL,
    can_have_gateways boolean NOT NULL,
    max_device_count integer NOT NULL,
    max_gateway_count integer NOT NULL,
    private_gateways_up boolean NOT NULL,
    private_gateways_down boolean NOT NULL,
    tags jsonb NOT NULL
);


ALTER TABLE public.tenant OWNER TO chirpstack;

--
-- Name: tenant_user; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public.tenant_user (
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_admin boolean NOT NULL,
    is_device_admin boolean NOT NULL,
    is_gateway_admin boolean NOT NULL
);


ALTER TABLE public.tenant_user OWNER TO chirpstack;

--
-- Name: user; Type: TABLE; Schema: public; Owner: chirpstack
--

CREATE TABLE public."user" (
    id uuid NOT NULL,
    external_id text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_admin boolean NOT NULL,
    is_active boolean NOT NULL,
    email text NOT NULL,
    email_verified boolean NOT NULL,
    password_hash character varying(200) NOT NULL,
    note text NOT NULL
);


ALTER TABLE public."user" OWNER TO chirpstack;

--
-- Data for Name: __diesel_schema_migrations; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.__diesel_schema_migrations (version, run_on) FROM stdin;
00000000000000	2026-06-02 01:11:42.336049
20220426153628	2026-06-02 01:11:43.309767
20220428071028	2026-06-02 01:11:43.323112
20220511084032	2026-06-02 01:11:43.324738
20220614130020	2026-06-02 01:11:43.338973
20221102090533	2026-06-02 01:11:43.343523
20230103201442	2026-06-02 01:11:43.345771
20230112130153	2026-06-02 01:11:43.347922
20230206135050	2026-06-02 01:11:43.349441
20230213103316	2026-06-02 01:11:43.354263
20230216091535	2026-06-02 01:11:43.356282
20230925105457	2026-06-02 01:11:43.373636
20231019142614	2026-06-02 01:11:43.377821
20231122120700	2026-06-02 01:11:43.381916
20240207083424	2026-06-02 01:11:43.383841
20240326134652	2026-06-02 01:11:43.386717
20240430103242	2026-06-02 01:11:43.39292
20240613122655	2026-06-02 01:11:43.403007
20240916123034	2026-06-02 01:11:43.407102
20241112135745	2026-06-02 01:11:43.408761
20250113152218	2026-06-02 01:11:43.414974
20250121093745	2026-06-02 01:11:43.424404
20250605100843	2026-06-02 01:11:43.441241
20250804085822	2026-06-02 01:11:43.443125
20251001085546	2026-06-02 01:11:43.444899
202511111404590000	2026-06-02 01:11:43.446558
202512101058490000	2026-06-02 01:11:43.45518
202602181001240000	2026-06-02 01:11:43.457396
\.


--
-- Data for Name: api_key; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.api_key (id, created_at, name, is_admin, tenant_id, is_read_only) FROM stdin;
\.


--
-- Data for Name: application; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.application (id, tenant_id, created_at, updated_at, name, description, mqtt_tls_cert, tags) FROM stdin;
043f1ddd-a0c1-457b-ae5e-0573979c0b45	77ec53ab-0069-4739-8935-3391005ce8b5	2026-06-02 10:57:20.633971+08	2026-06-02 10:57:20.633971+08	earn doggy		\N	{}
1f53f9a4-467f-4a6c-89d6-36a66842326a	2aa43e59-68f9-4d56-b2c3-937cf0dd4525	2026-06-12 21:32:31.503836+08	2026-06-12 21:32:31.503836+08	Camera_Node		\N	{}
\.


--
-- Data for Name: application_integration; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.application_integration (application_id, kind, created_at, updated_at, configuration) FROM stdin;
043f1ddd-a0c1-457b-ae5e-0573979c0b45	InfluxDb	2026-07-21 11:07:46.912329+08	2026-07-21 11:07:46.912329+08	{"InfluxDb": {"db": "chirpstack", "token": "REDACTED", "bucket": "", "version": 0, "endpoint": "http://localhost:8086/write", "password": "REDACTED", "username": "admin", "precision": 3, "organization": "", "retention_policy_name": ""}}
\.


--
-- Data for Name: device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device (dev_eui, application_id, device_profile_id, created_at, updated_at, last_seen_at, scheduler_run_after, name, description, external_power_source, battery_level, margin, dr, latitude, longitude, altitude, dev_addr, enabled_class, skip_fcnt_check, is_disabled, tags, variables, join_eui, secondary_dev_addr, device_session, app_layer_params, f_cnt_up) FROM stdin;
\\x4fee4d3dcb746b45	1f53f9a4-467f-4a6c-89d6-36a66842326a	60971949-e5e0-47c0-a527-8e4544ece0f8	2026-06-12 21:34:07.032429+08	2026-06-12 21:34:07.032429+08	\N	\N	Camera_Node		f	\N	\N	\N	\N	\N	\N	\\x019896a5	A	t	f	{}	{}	\\x0000000000000000	\N	\N	{"ts004_session_cnt": [0, 0, 0, 0]}	0
\\x70b3d57ed0077801	043f1ddd-a0c1-457b-ae5e-0573979c0b45	c416bab4-fbae-4281-b695-26a3daa748f6	2026-07-10 21:08:42.082862+08	2026-07-10 21:08:42.082862+08	2026-10-01 16:18:50.067004+08	2026-10-01 16:18:55.057573+08	insect-node-01	IMX500 insect counter	f	\N	11	5	\N	\N	\N	\\x00299a09	A	f	f	{}	{}	\\x0000000000000000	\N	\N	{"ts004_session_cnt": [0, 0, 0, 0]}	7
\\x70b3d57ed00778cc	043f1ddd-a0c1-457b-ae5e-0573979c0b45	a7e919f6-805b-4738-9ee5-6a8f916fde83	2026-06-02 19:40:54.252498+08	2026-07-20 22:03:03.520606+08	2026-10-01 15:34:49.785661+08	2026-10-01 15:34:54.772551+08	Lora node		f	\N	10	5	\N	\N	\N	\\x00793a73	A	f	f	{}	{}	\\x0000000000000000	\N	\N	{"ts004_session_cnt": [0, 0, 0, 0]}	9
\.


--
-- Data for Name: device_keys; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_keys (dev_eui, created_at, updated_at, nwk_key, app_key, dev_nonces, join_nonce, gen_app_key) FROM stdin;
\\x70b3d57ed0077801	2026-07-10 21:31:26.133424+08	2026-10-01 14:47:31.12738+08	\\x00000000000000000000000000000000	\\x00000000000000000000000000000000	{"0000000000000000": [47396, 13183, 62080, 25487, 36745, 13392, 58301, 43753, 16716, 61272, 20157, 30962, 4280, 57630, 22786, 5906, 42547, 47923, 37030, 20312, 35555, 37132, 50227, 10970, 52780, 40299, 59339, 44535, 16035, 41938, 23284, 15303, 12274, 61448, 508, 43915, 29230, 62578, 48993, 51881, 59119, 17359]}	42	\\x00000000000000000000000000000000
\\x70b3d57ed00778cc	2026-06-02 19:44:15.118305+08	2026-10-01 15:28:42.393297+08	\\x00000000000000000000000000000000	\\x00000000000000000000000000000000	{"0000000000000000": [5451, 51391, 38026, 41263, 20198, 38728, 21841, 25944, 4000, 61903, 63770, 24325, 31222, 46344, 48416, 40032, 2400, 46608, 38403, 59766, 57485, 36793, 40831, 58287, 19619, 19157, 6063, 49890, 30805, 50234, 5121, 32970, 513, 7179, 45771, 25497, 3757, 18251, 56728, 26851, 7070, 41254, 40492, 33452, 43208, 63368, 55120, 41444, 64502, 3662, 2097, 55941, 47057, 63101, 51843, 24266, 60965, 44243, 42448, 65063, 20701, 14677, 27352]}	84	\\x00000000000000000000000000000000
\\x4fee4d3dcb746b45	2026-06-12 21:34:45.000961+08	2026-08-24 23:26:47.518209+08	\\x00000000000000000000000000000000	\\x00000000000000000000000000000000	{"0000000000000000": [55292, 51926, 4093, 2239, 62351, 38667, 13799, 65500, 31988, 11258, 23812, 23936, 41628, 31287, 61182, 21683, 59007, 8645, 762, 32802, 34147, 58208, 7336, 14029, 21709, 29917, 64421, 10371, 25742, 54500, 3913, 50804, 50014, 42729, 58557, 9891, 54862, 43492, 22700, 26478, 565, 41562, 47759, 45221, 21883, 46211, 31082, 57439, 60392, 25476, 7370, 21443, 19671, 3077, 60656, 24525, 38599, 21584, 39843, 5052, 38564, 64760, 32154, 26105, 51079, 65187, 45644, 40819, 31031, 54343, 27803, 35088, 13023, 50351, 32539, 52934, 5627, 46135, 16455, 54075, 49419, 45026, 60663, 12741, 6926, 29496, 7363, 30946, 3350, 1501, 14942, 34197, 54090, 16824, 29117, 16120, 52138, 18653, 64633, 10489, 15761, 17353, 17143, 5820, 36267, 44886, 63347, 17962, 7252, 23047, 46922, 58918, 40825, 35436, 41421, 29709, 52392, 23913, 24947, 36369, 7610, 36821, 57123, 29915, 4009, 63707, 25275, 64494, 58578, 7326, 37709, 37943, 43703, 53710, 46515, 59167, 27746, 57926, 44647, 3130, 26758, 50090, 41650, 35878, 49523, 38660, 48671, 45037, 27361, 9569, 3185, 20439, 34005, 40553, 1303, 31065, 40998, 62819, 5175, 37957, 57158, 58952, 281, 2137, 65524, 7642, 46954, 21475, 3465, 24191, 25243, 3470, 5063, 9171, 2590, 55221, 21193, 3123, 2406, 49669, 48057, 49932, 10, 18692, 27568, 44834, 21246, 62188, 15178, 15848, 31980, 13553, 54242, 44407, 30589, 50440, 44066, 166, 24339, 1797, 25203, 34651, 33479, 59307, 23331, 17761, 8431, 8192, 60840, 37970, 31648, 30766, 58842, 2125, 41228, 18738, 39100, 55105, 6562, 45348, 65084, 5909, 39102, 26308, 49124, 52509, 12149, 6253, 52382, 59662, 39813, 55669, 47878, 27622, 52053, 6093, 59777, 2003, 28137, 53447, 5322, 8941, 20338, 38249, 8299, 6558, 31153, 42399, 54225, 21827, 50744, 1904, 8084, 30457, 32356, 62769, 36555, 24737, 30933, 35523, 24816, 22254, 19623, 24148, 12188, 32091, 27414, 63061, 58043, 55333, 52500, 32099, 22903, 64166, 1548, 20037, 16775, 58204, 10924, 22621, 63093, 10992, 19225, 59614, 4068, 10355, 22266, 29108, 13438, 27838, 12465, 23980, 16282, 961, 59613, 2169, 33417, 23993, 44192, 61471, 34938, 5843, 8358, 55664, 5893, 52676, 22081, 41908, 30431, 65182, 54698, 53119, 53122, 14041, 35959, 43725, 64492, 5628, 52227, 61934, 39773, 35178, 21533, 26247, 17644, 47709, 13616, 44207, 63187, 12229, 8915, 32638, 52655, 7681, 57698, 40276, 12040, 35391, 56968, 41243, 60003, 25253, 44952, 12145, 47184, 18432, 53767, 541, 16265, 52814, 19921, 43231, 51201, 44510, 37506, 32676, 21605, 8250, 29227, 6680, 21320, 1091, 19237, 61642, 40221, 64208, 4723, 13716, 27909, 21196, 10549, 40046, 50816, 58784, 56611, 48609, 6007, 48050, 49650, 2309, 56664, 13529, 2110, 39845, 61926, 16526, 63561, 18066, 41914, 24434, 61029, 42191, 47502, 42634, 4018, 24906, 20671, 40161, 29199, 58854, 60830, 56842, 25614, 35826, 7773, 38121, 13318, 22876, 55091, 405, 62941, 48561, 36880, 57849, 13098, 22389, 58176, 50175, 35214, 2905, 27529, 25570, 51651, 25445, 17939, 39850, 47122, 20552, 6389, 15446, 18788, 14237, 16527, 51458, 61285, 10672, 39864, 1513, 11685, 42039, 4227, 35907, 7586, 6963, 36528, 25454, 32257, 56930, 11899, 37495, 28643, 11208, 5813, 9914, 12875, 41986, 12439, 56905, 46222, 42914, 49214, 60181, 20306, 34997, 29432, 53609, 57309, 59100, 9896, 17310, 50759, 59088, 60134, 27897, 12654, 44898, 52354, 58421, 18304, 8983, 22651, 59358, 62765, 40829, 30155, 13968, 61726, 23974, 51768, 49921, 11262, 25822, 19310, 65516, 56249, 50387, 63339, 46564, 53797, 8384, 60893, 26983, 23354, 62408, 15822, 22346, 49275, 6204, 42730, 39341, 16446, 54999, 43260, 49198, 51224, 12317, 59837, 19632, 30904, 50103, 31263, 5707, 39198, 5414, 21234, 22856, 29098, 40143, 35412, 1648, 58685, 33723, 35805, 44118, 56766, 10940, 25517, 9658, 34028, 31436, 33056, 2419, 36517, 48334, 41115, 42031, 22083, 33948, 59802, 5633, 27168, 41321, 8403, 46098, 60253, 24711, 35257, 61219, 34210, 49790, 20329, 5405, 51723, 38755, 21504, 52188, 42260, 60486, 43039, 45871, 12076, 34072, 13462, 14373, 21655, 59332, 45132, 24492, 50396, 32761, 6841, 48953, 29948, 54838, 8162, 14874, 37, 36797, 19263, 47912, 8114, 25739, 21752, 59411, 56747, 30701, 13408, 28648, 27850, 24902, 13076, 63620, 31993, 59812, 36187, 33236, 7953, 35350, 57416, 12347, 50739, 61209, 14664, 1241, 19711, 57128, 25734, 54496, 50822, 1987, 42742, 23413, 56843, 20805, 28497, 27673, 55962, 37573, 20947, 46645, 41411, 3506, 50692, 48805, 13899, 8961, 8873, 46240, 54858, 65406, 41909, 18367, 35883, 56441, 17037, 58333, 26539, 48962, 62003, 25501, 29648, 26908, 62842, 39539, 5421, 62216, 26770, 58942, 42431, 19024, 32711, 45573, 33142, 53197, 28507, 43794, 54653, 22512, 24250, 33171, 19990, 16832, 64585, 5266, 10838, 17944, 30980, 26085, 2904, 47186, 45122, 39995, 61528, 6, 44549, 25159, 31296, 17349, 55462, 28923, 28819, 46386, 936, 63231, 28920, 3726, 20734, 34199, 2953, 35460, 22097, 58602, 14033, 34574, 22475, 15363, 53851, 10139, 44884, 23332, 4481, 23791, 30271, 7283, 8775, 53786, 10247, 3399, 62358, 24614, 12695, 4668, 38446, 65527, 38001, 6044, 938, 26365, 54800, 8913, 7436, 16623, 47896, 50255, 60577, 23350, 23804, 28771, 12468, 27621, 11036, 62326, 13059, 29191, 54782, 18753, 19846, 33337, 42825, 20643, 15192, 21002, 52722, 27016, 39626, 40642, 9501, 38233, 49248, 36331, 47680, 32322, 48977, 8138, 34942, 46589, 48260, 6457, 49258, 54822, 58879, 18351, 37927, 53156, 42866, 12233, 41556, 42471, 25596, 4653, 16791, 49330, 14078, 643, 57609, 58957, 13487, 47522, 58007, 59681, 43982, 20558, 57766, 19129, 46090, 39623, 41163, 3615, 3353, 28634, 28069, 50258, 59165, 4585, 12568, 34371, 40898, 5809, 27608, 25101, 1600, 51118, 23816, 2653, 57599, 29830, 61322, 36274, 25510, 10380, 24063, 38579, 31929, 44795, 22036, 16349, 40676, 7139, 12101, 3928, 2481, 47556, 41424, 34801, 3585, 18656, 24578, 8168, 54037, 25555, 63015, 58893, 11803, 40392, 55529, 46257, 59259, 1165, 39561, 22206, 2014, 30730, 3893, 58598, 61957, 24269, 29029, 14444, 6862, 40733, 58233, 52674, 52682, 36259, 1477, 27040, 748, 19265, 63973, 59002, 23428, 63683, 10360, 55046, 9763, 40411, 61565, 55956, 48859, 54432, 20265, 24222, 42270, 31207, 51389, 58690, 5031, 59482, 8950, 54628, 40377, 61147, 41445, 48728, 61088, 12191, 53242, 24071, 50417, 43700, 31380, 21129, 32370, 64044, 5440, 54995, 63874, 18270, 37679, 25331, 2023, 35113, 19583, 49218, 62217, 33014, 35783, 56412, 44721, 60923, 54463, 47777, 57118, 38694, 8975, 60665, 7861, 59782, 53809, 47987, 42489, 29444, 54523, 29784, 22102, 33057, 7635, 5260, 62, 32069, 50506, 12935, 45076, 5450, 47538, 46283, 50733, 57109, 64956, 40919, 36241, 50571, 51315, 26522, 13729, 22926, 15960, 8347, 8127, 16921, 54083, 45033, 42664, 20015, 27611, 62759, 32440, 52215, 20229, 59422, 28687, 1222, 52429, 33336, 2450, 19287, 35431, 15162, 62199, 972, 34035, 39748, 9361, 64665, 3840, 25521, 17255, 29922, 17089, 59922, 53814, 14424, 44337, 36814, 51683, 9571, 41864, 20152, 53755, 63875, 35613, 57554, 21483, 8321, 61992, 5854, 1289, 64614, 31934, 21136, 54431, 10181, 54724, 43649, 59253, 6576, 19838, 12429, 23185, 58385, 48247, 53949, 25708, 53327, 40979, 63902, 23583, 25479, 10955, 60404, 34484, 62341, 46829, 50647, 36907, 4646, 36446, 13279, 60307, 34019, 3338, 59458, 23854, 53868, 33873, 38749, 34290, 13823, 51925, 48404, 12962, 56188, 51672, 7349, 42715, 13401, 64668, 8681, 19897, 64380, 59342, 29391, 58441, 16696, 64715, 47561, 43404, 64938, 59550, 9771, 42645, 21120, 7304, 51666, 27846, 63176, 39484, 12357, 3400, 10312, 58453, 29208, 5461, 60464, 57963, 3418, 51746, 2380, 21559, 33201, 54349, 32738, 55140, 59349, 3835, 31421, 39607, 60579, 19315, 15622, 45775, 20420, 24212, 46881, 60278, 22170, 61094, 35044, 50945, 53575, 10995, 41963, 38931, 956, 20784, 18557, 10128, 52729, 44786, 49662, 6407, 48418, 6358, 34775, 3912, 18262, 60039, 10510, 50914, 22962, 52318, 65059, 4008, 6608, 31638, 28936, 57038, 10090, 44607, 63235, 47694, 34228, 46517, 21957, 25855, 15404, 1424, 14788, 34375, 54397, 10297, 36737, 6332, 41871, 7646, 37374, 39178, 29589, 61660, 9108, 33915, 60062, 11378, 9686, 12845, 53574, 62900, 10777, 26224, 55763, 37031, 30571, 58167, 59397, 43243, 56466, 542, 54462, 31925, 56043, 41193, 29599, 1018, 59593, 34004, 14344, 28992, 187, 26291, 19821, 1540, 20097, 31876, 33037, 47221, 51669, 3888, 28811, 44378, 50610, 44691, 54870, 9329, 28232, 61705, 57341, 64373, 60207, 27092, 12152, 35760, 32054, 13116, 37483, 50855, 50950, 50231, 48248, 36628, 25054, 55213, 35131, 16514, 8638, 7300, 33075, 19071, 4182, 7360, 30238, 36747, 25166, 5902, 9336, 5315, 18423, 57730, 51861, 54894, 24847, 27081, 2900, 31332, 12364, 57218, 49654, 14981, 57075, 421, 44846, 9118, 39620, 24916, 59955, 5313, 16712, 16398, 46921, 54205, 19965, 55963, 10680, 34731, 31038, 8178, 39847, 44412, 52452, 10357, 14799, 48451, 4097, 37392, 22538, 44050, 54453, 41790, 53749, 42212, 57942, 56328, 17220, 9972, 9966, 36111, 22367, 64778, 39749, 16494, 39892, 10565, 18401, 45173, 55472, 64702, 45242, 53113, 21121, 37444, 22988, 12047, 54635, 48200, 17018, 47136, 44900, 50905, 15806, 23011, 44634, 55375, 9729, 63368, 61763, 34209, 42929, 9889, 14274, 57594, 21049, 58152, 64387, 51673, 21848, 18418, 34728, 7025, 27548, 7911, 45908, 16227, 49385, 58752, 44067, 37310, 49870, 30377, 8573, 8281, 57625, 6610, 34736, 10165, 6859, 54154, 17050, 39441, 1669, 65155, 23381, 5048, 63797, 53136, 12249, 63196, 28220, 45684, 52155, 38372, 42427, 23914, 64857, 37316, 6905, 54018, 57632, 56331, 20917, 47629, 51025, 49137, 27967, 21356, 49655, 44022, 28123, 2431, 12423, 4194, 35822, 6946, 13484, 56783, 12986, 60777, 42888, 3006, 47061, 40159, 22574, 63921, 54168, 31370, 44892, 33755, 1265, 49658, 28017, 30292, 22615, 47294, 19581, 24714, 48348, 4695, 38981, 45818, 12914, 2326, 61268, 43716, 58123, 51918, 1287, 57954, 60419, 19469, 36226, 36738, 3415, 39998, 55284, 61484, 9419, 40228, 29035, 39778, 1232, 11020, 64319, 48049, 36319, 43362, 25878, 25716, 11273, 28743, 42669, 25163, 59194, 11978, 33080, 47933, 12575, 28013, 49705, 4529, 56062, 5425, 51154, 17453, 45456, 15921, 48186, 50990, 22628, 48187, 63150, 36925, 27540, 17136, 20177, 49697, 33378, 10836, 38201, 20995, 12014, 41316, 6377, 24853, 12088, 10625, 50308, 31429, 51885, 2189, 13291, 65014, 4269, 19524, 8324, 20524, 46749, 60599, 49398, 37515, 41613, 1875, 33012, 2446, 16703, 42854, 43342, 6738, 17454, 40455, 30352, 62760, 33099, 62980, 41083, 14816, 47251, 53943, 3160, 30396, 47281, 9045, 51166, 14069, 44697, 14505, 13800, 63050, 17398, 43298, 55099, 2011, 49759, 2401, 26031, 52622, 49679, 34391, 27941, 52799, 57331, 44833, 3987, 20518, 26992, 57734, 14479, 29263, 47380, 38111, 36937, 36584, 29804, 43070, 5789, 20695, 37829, 29374, 11872, 7077, 20823, 55198, 15620, 1296, 35035, 27645, 54539, 48945, 10840, 48132, 39245, 21573, 32973, 50869, 30294, 26977, 3129, 29698, 10501, 61272, 2807, 52242, 60771, 25866, 28027, 46786, 58667, 57679, 60658, 51106, 29518, 59313, 2960, 19620, 49000, 62631, 40179, 1878, 27655, 21067, 12572, 19791, 18104, 57144, 56087, 325, 51609, 161, 36527, 21877, 59709, 65401, 41565, 20231, 60225, 25998, 12046, 21495, 7214, 12632, 38375, 17013, 54019, 35316, 63043, 27767, 23356, 16863, 33398, 42772, 16308, 3622, 55347, 8461, 42340, 10529, 50568, 62728, 8061, 37170, 29150, 46176, 43382, 8452, 10725, 53533, 6067, 1075, 217, 59535, 57669, 6038, 17782, 38879, 21586, 37129, 58417, 30360, 27321, 13470, 56002, 7052, 43242, 28933, 48641, 5312, 40316, 53448, 26287, 10897, 18858, 27786, 21689, 42995, 36944, 24628, 47327, 29486, 50370, 9697, 63679, 10235, 14359, 10575, 40026, 3247, 18073, 36069, 23840, 37628, 48491, 29369, 7050, 47016, 55327, 46077, 48387, 11721, 16969, 29595, 38868, 64127, 3991, 60986, 50787, 11948, 48637, 5283, 9570, 61488, 24780, 50109, 65231, 59437, 60316, 38325, 6705, 10740, 27724, 26581, 11513, 16263, 15394, 49838, 56687, 21402, 3985, 23877, 18065, 52334, 54887, 9192, 62766, 62078, 41814, 49851, 32247, 50551, 43695, 40223, 23480, 46652, 62926, 62354, 49267, 11977, 32072, 27024, 41248, 14440, 47853, 11600, 22534, 51023, 55453, 15886, 44294, 27864, 12544, 9817, 4051, 52252, 61607, 24722, 15980, 57438, 62901, 7998, 52177, 56194, 1465, 28250, 41777, 7576, 42933, 57726, 43898, 57492, 17994, 1892, 57405, 18149, 35183, 48639, 20120, 21777, 64579, 63922, 19770, 33563, 10701, 40269, 30295, 45217, 35506, 338, 39051, 37575, 29024, 8105, 37569, 34581, 39487, 29534, 16898, 47265, 1126, 12779, 54389, 255, 19079, 2968, 17505, 41008, 12068, 29538, 59195, 31817, 57372, 30618, 28227, 13975, 28975, 23150, 16517, 11222, 45650, 62594, 55128, 54063, 54623, 19452, 60653, 5289, 63011, 60348, 42046, 59669, 35723, 61577, 25653, 64198, 29446, 61478, 61939, 5651, 12448, 44164, 15676, 45565, 35788, 16267, 18752, 36327, 45251, 64479, 34189, 58019, 11406, 34357, 14819, 21676, 26856, 52861, 34985, 2958, 43401, 10074, 16634, 56440, 1502, 50102, 12718, 51312, 59743, 55688, 25620, 13948, 32684, 24342, 42556, 60037, 29572, 65254, 42024, 8388, 11305, 50967, 55253, 58548, 8542, 1114, 42378, 3562, 41537, 48878, 49483, 52281, 49052, 18478, 26419, 33268, 33824, 59453, 21782, 28985, 17025, 31048, 32480, 36795, 23173, 11148, 43798, 13095, 33585, 5138, 57463, 48950, 11074, 323, 25688, 35763, 39962, 44401, 15203, 30477, 4547, 50791, 53137, 56791, 15652, 52456, 13048, 10870, 31374, 28230, 6094, 16726, 681, 14607, 23163, 30487, 19794, 5535, 57319, 61131, 16167, 6982, 62304, 23027, 54157, 42966, 50257, 43047, 34752, 27570, 31958, 39622, 65202, 1917, 53682, 29610, 10512, 25827, 25520, 39212, 24912, 12157, 61055, 34948, 23895, 51863, 22440, 20292, 18695, 23607, 49871, 10198, 21685, 5987, 63661, 53425, 58743, 16295, 3172, 63179, 24457, 46047, 3783, 1038, 5244, 8679, 30389, 34679, 45386, 65146, 34861, 51593, 11782, 43011, 4062, 58340, 29443, 16347, 29073, 41917, 64544, 14197, 33715, 23847, 27060, 24478, 63802, 4299, 44526, 49232, 4704, 10153, 29806, 34156, 47430, 7489, 29642, 403, 51987, 24275, 53916, 32246, 36695, 47397, 20505, 654, 60409, 6276, 24420, 48060, 62545, 62009, 11769, 17005, 57637, 62775, 6763, 37671, 24010, 21149, 9507, 2843, 25426, 41464, 55299, 9460, 36673, 40022, 64826, 44730, 18568, 9013, 57386, 63319, 15763, 61572, 47877, 45712, 17127, 15694, 24990, 32241, 65375, 24750, 51832, 61013, 11333, 53296, 54788, 49513, 50162, 12013, 60966, 32436, 19307, 13882, 17283, 38656, 52037, 40021, 53005, 23353, 758, 22892, 40566, 28160, 18855, 63957, 57639, 13867, 45097, 26220, 61549, 815, 5020, 12003, 57504, 46677, 56128, 57906, 20063, 44617, 19606, 6312, 5156, 15062, 36014, 32083, 5716, 48346, 18028, 53908, 62208, 61083, 61380, 14249, 57818, 14882, 5894, 63168, 52247, 30914, 11235, 50496, 40614, 9027, 56473, 9693, 53210, 48329, 50306, 6745, 12397, 27266, 38202, 19786, 25589, 40380, 10511, 21628, 4633, 12140, 19017, 50127, 20106, 41978, 17673, 45707, 51046, 27389, 18226, 5671, 4304, 19562, 12826, 42972, 37589, 23989, 10531, 25104, 28211, 26832, 4558, 46527, 27229, 60123, 26075, 4158, 39708, 62576, 60151, 38916, 52470, 23267, 63181, 17821, 8558, 25689, 36881, 6020, 15539, 53870, 10896, 23490, 10918, 48727, 6584, 56554, 2758, 3617, 42759, 18291, 21502, 47163, 47046, 44766, 50401, 44307, 34965, 13455, 52970, 17386, 62767, 57179, 5231, 57653, 12722, 56478, 62324, 16219, 19618, 45002, 54402, 47181, 48344, 37724, 22300, 58866, 31761, 19175, 13669, 29996, 55068, 57234, 55932, 41664, 40115, 51957, 29809, 58591, 21024, 254, 30087, 26979, 50788, 54829, 31079, 45878, 43886, 18965, 27114, 64858, 18181, 47291, 63130, 53384, 13346, 64251, 27927, 65369, 31217, 39617, 1617, 40042, 41286, 32871, 45738, 46151, 31472, 47188, 14761, 48844, 39423, 26927, 52149, 9309, 56693, 60718, 60740, 18344, 42822, 2914, 60667, 40873, 62272, 41770, 37682, 47383, 58051, 31602, 10835, 3533, 19825, 43073, 21876, 29751, 33526, 35952, 56920, 28419, 45949, 58125, 6638, 58569, 23797, 63177, 20937, 19631, 49624, 1658, 23399, 35724, 1547, 54174, 10782, 39161, 10681, 34561, 35837, 22596, 40804, 20218, 64199, 22880, 18431, 24997, 37850, 33224, 61175, 15861, 21952, 20083, 21679, 29488, 23697, 5899, 18647, 43066, 52097, 3270, 56400, 37296, 63733, 22746, 55760, 23818, 58938, 40083, 31491, 3431, 8313, 28363, 53600, 18012, 47466, 5416, 61198, 48831, 13688, 8443, 2154, 59590, 10425, 46731, 30648, 14475, 25069, 34140, 44828, 10040, 33646, 63329, 32864, 9375, 25727, 14348, 30690, 60237, 58328, 3618, 30037, 56351, 17733, 34890, 18668, 20760, 45018, 21598, 25706, 26546, 37440, 4309, 26409, 12978, 34506, 34190, 37437, 57968, 52769, 24953, 55346, 32862, 2104, 62437, 10418, 38841, 35062, 42550, 55266, 54689, 44156, 43528, 19824, 28398, 62790, 11719, 29938, 48120, 43447, 32431, 4057, 31477, 49696, 1252, 51255, 40440, 10649, 24572, 61017, 27210, 7885, 34246, 43726, 17869, 3965, 17938, 26492, 6573, 3976, 43946, 25381, 57783, 43367, 48642, 29387, 27950, 8910, 65312, 22710, 19749, 7616, 56570, 48526, 7976, 6322, 53320, 55020, 40548, 18910, 60516, 50495, 34912, 7125, 32350, 53368, 29422, 30512, 29906, 29519, 52839, 58669, 7490, 9280, 4473, 35806, 7733, 363, 55949, 43983, 18999, 23136, 5243, 16576, 13187, 47794, 56042, 13625, 58624, 63596, 16008, 16762, 20735, 64921, 58034, 45099, 7048, 53990, 23638, 5098, 8069, 57335, 54445, 9478, 16598, 13809, 21915, 29638, 10970, 7188, 2098, 23341, 56629, 12388, 12528, 22597, 2266, 27196, 39349, 53345, 8973, 62422, 62740, 10086, 1786, 57394, 11501, 38413, 38430, 39588, 43668, 63540, 55662, 9591, 27216, 57226, 42941, 11046, 1953, 15895, 40305, 5011, 27468, 28148, 53380, 4282, 29501, 48677, 31322, 55640, 64692, 38108, 54771, 15251, 43789, 18145, 53244, 61925, 18015, 42355, 56854, 15180, 16133, 42112, 31972, 25231, 49728, 20353, 27647, 49341, 2054, 52721, 65411, 29183, 50556, 52561, 44649, 34041, 34939, 41946, 4847, 62012, 33487, 21968, 2349, 64309, 62479, 41216, 45846, 62322, 34835, 15760, 42143, 5485, 11338, 30840, 36692, 36399, 34106, 2286, 47823, 54897, 48211, 8136, 25167, 19366, 18109, 28900, 33842, 8259, 42325, 61486, 18167, 56211, 47577, 3443, 54537, 24413, 39857, 9546, 9824, 22569, 64748, 42333, 2351, 33927, 33615, 26304, 14097, 43502, 5614, 18079, 43901, 14638, 52498, 5591, 7087, 19790, 35949, 32982, 324, 39491, 55683, 56483, 62486, 51163, 7475, 3702, 26146, 55427, 17974, 31191, 16606, 37113, 16034, 18193, 20089, 54361, 42065, 55754, 49575, 42820, 61220, 18049, 52118, 2111, 19803, 13790, 38035, 3033, 16817, 65387, 29356, 25, 34201, 44556, 31192, 4155, 61588, 26540, 20834, 2013, 7723, 61339, 9996, 46439, 29652, 47080, 21125, 6138, 8788, 38517, 45517, 52091, 52953, 44459, 44595, 3489, 43997, 39862, 49399, 28644, 50241, 60540, 58435, 60417, 56358, 9059, 30587, 60412, 51731, 49878, 42725, 28999, 23730, 33206, 32631, 60780, 64643, 5539, 6885, 45923, 28453, 48012, 44290, 33510, 63650, 7835, 13274, 13905, 9035, 45455, 11702, 14382, 45147, 27626, 21162, 6248, 64541, 46134, 32913, 54105, 53214, 35161, 44744, 37399, 41353, 30652, 41360, 16945, 23875, 539, 35540, 42178, 3683, 15477, 17191, 25365, 34151, 16177, 61123, 34421, 16999, 26214, 50983, 32576, 213, 17985, 4345, 64658, 10526, 22119, 12583, 54969, 61493, 24464, 13148, 61597, 38357, 29338, 7267, 31312, 43138, 16477, 37281, 34910, 32829, 33952, 36537, 40930, 46860, 41834, 43075, 39876, 31949, 33514, 28953, 60844, 3413, 8485, 37546, 51213, 64526, 1180, 48194, 20478, 55728, 35771, 15899, 21491, 11701, 16779, 10122, 14338, 19279, 47860, 49792, 44068, 41374, 39047, 16844, 33415, 27999, 6996, 30931, 20614, 26993, 10270, 58266, 51587, 38482, 51605, 46419, 17546, 49497, 24224, 24032, 18630, 10717, 47057, 63793, 13568, 15491, 42679, 52067, 3896, 54104, 22939, 65368, 7392, 38094, 53434, 40533, 63222, 36772, 15486, 18645, 49072, 28714, 64967, 23169, 46535, 33876, 29863, 42961, 4192, 25171, 29397, 850, 58796, 57182, 7449, 29565, 42082, 26528, 24343, 49158, 61224, 47592, 35246, 58564, 57924, 3695, 5369, 32237, 29651, 49160, 12619, 35974, 9318, 15510, 47757, 24121, 47206, 24267, 58231, 40168, 25868, 61054, 56756, 42708, 51297, 36140, 35326, 26439, 41676, 35677, 50665, 32116, 42677, 46862, 49835, 4211, 32169, 26500, 9596, 64412, 47737, 19861, 58631, 41780, 46463, 55264, 43968, 4145, 49574, 16405, 2697, 57828, 6911, 37182, 10958, 26890, 159, 52733, 51152, 48666, 49817, 8252, 61012, 35097, 19644, 43650, 8479, 4329, 54985, 59218, 40019, 28003, 48435, 60344, 59102, 41649, 60098, 26405, 55820, 35756, 62888, 44537, 61866, 2720, 8942, 12993, 63940, 35706, 3693, 58077, 44375, 2917, 59170, 10293, 2448, 37629, 60510, 31772, 9034, 22645, 32362, 6347, 30731, 33450, 63332, 37266, 40952, 13300, 40450, 64575, 62134, 8353, 13582, 53959, 48070, 12362, 41487, 24949, 12483, 4364, 18441, 23629, 64909, 1564, 40424, 38007, 10468, 17818, 17995, 5363, 3468, 47128, 34121, 22826, 31070, 23435, 22722, 7156, 1585, 29939, 45197, 11578, 45209, 13227, 20821, 36190, 15321, 41591, 14177, 212, 983, 19137, 40702, 62756, 17865, 64260, 33991, 53934, 15787, 22262, 2084, 7807, 14439, 3900, 8373, 14723, 24352, 61747, 44623, 42415, 26991, 18338, 17396, 46455, 25590, 58714, 43004, 14110, 13444, 59764, 44806, 55360, 5286, 37673, 15085, 54601, 49446, 37335, 54287, 33061, 19587, 50673, 28413, 22704, 32649, 58699, 12906, 65015, 25799, 13273, 1185, 59287, 48947, 48808, 24657, 33545, 24211, 4451, 11737, 46951, 10705, 545, 10707, 53435, 9953, 40250, 28716, 27624, 53539, 5925, 24897, 20786, 50478, 14340, 58470, 41329, 21606, 63916, 59970, 1777, 22281, 39985, 64234, 18306, 29577, 5787, 5766, 8418, 62070, 32244, 2367, 31533, 15463, 9431, 3449, 14992, 4013, 61240, 50509, 36984, 41804, 5884, 22172, 15610, 36701, 3914, 34234, 41113, 21609, 3827, 51694, 46456, 36016, 16292, 16149, 44124, 64917, 8269, 36138, 10570, 32581, 514, 48632, 8199, 19436, 18729, 23785, 1979, 32825, 50063, 40385, 29060, 62203, 21432, 36065, 12263, 1583, 40064, 20912, 9785, 10583, 33515, 40928, 56885, 22151, 47384, 36786, 52858, 54976, 26572, 24004, 52841, 1390, 49315, 30494, 58869, 24524, 2887, 30166, 22912, 65287, 50549, 6316, 34314, 21569, 34095, 21794, 17426, 45593, 57219, 38453, 27679, 62511, 12426, 5795, 5739, 42660, 6855, 61452, 11431, 55526, 6565, 2232, 38751, 48262, 27445, 34240, 52002, 6617, 2247, 59629, 33412, 26694, 42596, 27454, 41254, 54534, 36426, 6746, 34992, 34583, 31871, 42743, 15634, 32805, 34289, 38778, 31446, 40876, 43100, 40583, 21299, 57861, 48741, 16159, 37875, 12131, 27463, 32828, 28111, 9945, 65054, 36635, 16979, 30054, 40290, 10652, 1488, 22905, 453, 62193, 46485, 26633, 29746, 35007, 6965, 48502, 6155, 63380, 45022, 57211, 16654, 1309, 59687, 52642, 39641, 57971, 55158, 20770, 5281, 24096, 57630, 591, 37226, 61280, 19543, 25751, 55118, 46282, 57153, 51750, 3492, 1567, 38994, 58424, 31535, 46200, 23221, 4279, 31316, 36304, 32789, 26088, 35600, 33445, 45632, 8329, 14636, 62882, 3145, 57703, 18944, 57006, 32658, 17389, 55674, 30591, 962, 43097, 59827, 50031, 64604, 57124, 28329, 3747, 48592, 17497, 32560, 39593, 43881, 24623, 50259, 5512, 58994, 22209, 28544, 21740, 28866, 65318, 45405, 33385, 34660, 33525, 5174, 5552, 55744, 37078, 21652, 31549, 34403, 13731, 35387, 38379, 17987, 20133, 54617, 53917, 54669, 33151, 33856, 31974, 28838, 55358, 59201, 27758, 59145, 63102, 26273, 51748, 55736, 29450, 59801, 29348, 7904, 63240, 27296, 22077, 9441, 63112, 44178, 53181, 35114, 18697, 52460, 12928, 44665, 2594, 23637, 36668, 17481, 33062, 28143, 17633, 12086, 10439, 10895, 17811, 18716, 35655, 63840, 65226, 22734, 11593, 11416, 11449, 14571, 55849, 14305, 61948, 53324, 51646, 26123, 16605, 43108, 9741, 6438, 16, 23137, 20049, 24910, 30656, 55685, 65389, 43420, 51684, 21879, 56455, 49293, 46977, 43110, 63594, 24830, 23243, 6737, 59835, 56810, 10027, 5643, 3265, 1734, 35720, 5886, 56909, 15272, 42313, 52570, 45442, 65251, 14863, 23507, 19820, 34982, 14897, 7987, 57958, 34029, 41257, 10735, 54575, 61398, 2177, 27559, 8332, 31113, 8397, 36169, 4428, 4070, 60306, 59537, 54301, 37242, 43733, 14864, 46491, 4518, 15592, 62714, 25951, 42965, 28539, 43393, 15213, 4106, 64223, 2482, 23790, 10443, 30851, 1151, 53208, 21741, 33342, 48877, 8604, 14100, 42408, 12778, 8462, 63178, 63967, 61797, 21726, 60737, 42359, 15589, 35271, 4041, 20110, 33897, 49337, 54469, 40694, 35957, 2371, 42138, 30146, 38192, 49033, 3131, 13547, 40311, 17493, 31853, 46458, 3341, 46138, 55104, 53427, 62488, 10229, 61234, 62553, 43442, 10303, 15646, 39697, 12470, 10382, 18330, 7844, 40710, 45657, 34015, 53691, 47603, 37747, 62613, 46398, 1981, 418, 15098, 48925, 30024, 9304, 51517, 14047, 31496, 4998, 44603, 31459, 30337, 15552, 57448, 54735, 11863, 23771, 37823, 53445, 46889, 60789, 8476, 58811, 32023, 9131, 24029, 22105, 3405, 37855, 50510, 39944, 34946, 45482, 32490, 47619, 2284, 29290, 58785, 33182, 46825, 43192, 13129, 30776, 44600, 6512, 28608, 9762, 9616, 17847, 28651, 21909, 54691, 58261, 43818, 51833, 8465, 12323, 62452, 30647, 16548, 44544, 34124, 19075, 30875, 28086, 49990, 13610, 33084, 2201, 2012, 41034, 53773, 29647, 18519, 63727, 43331, 27573, 22203, 38248, 12536, 13445, 61009, 21184, 18211, 51190, 33971, 56044, 52451, 53446, 13775, 20046, 17484, 64025, 940, 38445, 2403, 33813, 5278, 34592, 28669, 64923, 45392, 52935, 64769, 18174, 50143, 43230, 6244, 33746, 57268, 10298, 6456, 5827, 53472, 19344, 47346, 17591, 813, 53035, 25648, 18517, 43085, 24863, 20061, 50327, 50797, 23512, 37879, 4293, 51752, 31460, 8929, 27039, 54129, 52614, 30786, 34090, 28958, 34785, 37918, 48699, 2409, 19007, 16652, 58666, 1249, 18903, 8455, 52367, 61253, 34157, 11999, 11468, 24399, 36691, 27462, 24214, 22979, 30078, 63495, 33509, 59781, 3020, 56055, 27497, 55307, 48934, 40517, 31921, 45208, 58592, 33623, 64950, 9277, 49715, 11401, 9102, 56325, 13043, 61465, 40871, 42710, 16212, 12297, 31712, 26589, 59884, 58538, 32231, 60957, 25113, 56927, 12476, 33092, 56660, 45294, 25310, 25485, 13236, 991, 51156, 15711, 18555, 36285, 43581, 31179, 42544, 5865, 8862, 10703, 37009, 49866, 57597, 47886, 19305, 43849, 30472, 54195, 27824, 13380, 27363, 20958, 38619, 19682, 58188, 52457, 11432, 27049, 3549, 2842, 51143, 21985, 16611, 1333, 8841, 25261, 11595, 3767, 52607, 47638, 17024, 32484, 2500, 37542, 48455, 17652, 51655, 42600, 27968, 26303, 6756, 31982, 52173, 52494, 1836, 28595, 16041, 7291, 43628, 43466, 5459, 10134, 58877, 58678, 42956, 60049, 60393, 16031, 29914, 35048, 14970, 1597, 41033, 23139, 62532, 23807, 52653, 10937, 65294, 29586, 25467, 64469, 34927, 39052, 15204, 27615, 21145, 12649, 31122, 35347, 56550, 45998, 33918, 48214, 18625, 56696, 9584, 25769, 27120, 35792, 54032, 63866, 4582, 20527, 51442, 17900, 54055, 60175, 3113, 37407, 43048, 60055, 60286, 64959, 30879, 8181, 1089, 1883, 31930, 35147, 27429, 38722, 51566, 57152, 9707, 13434, 37608, 13181, 49726, 26536, 623, 54473, 8756, 27270, 19839, 10374, 52373, 29429, 14335, 5040, 59854, 64139, 42174, 18472, 38693, 1235, 43568, 49123, 20780, 8229, 27209, 45779, 65136, 45682, 32413, 38272, 64710, 12184, 34689, 10881, 52887, 2556, 3825, 24036, 37309, 20088, 53318, 48786, 45254, 56086, 47974, 503, 8585, 53474, 50652, 7585, 27580, 38366, 18123, 39287, 28428, 5696, 2443, 7608, 43038, 29411, 37944, 61865, 57414, 28133, 49207, 56013, 13757, 26485, 25754, 16920, 21178, 4303, 30382, 22269, 30304, 22585, 44918, 27698, 62517, 11618, 27849, 11029, 59354, 13811, 12412, 20410, 12044, 23647, 25155, 28707, 58865, 25562, 7636, 17928, 18935, 24169, 46483, 5317, 53726, 659, 15172, 43314, 23020, 64879, 49801, 57471, 34445, 36624, 2141, 59528, 34245, 26054, 59062, 26403, 57919, 61307, 9521, 50453, 1485, 29254, 19927, 44213, 51454, 27383, 18056, 31587, 42604, 23614, 21131, 36712, 24538, 23071, 353, 34793, 789, 38853, 2311, 13764, 35935, 29771, 43022, 48103, 48433, 48796, 12831, 61728, 13794, 18358, 37745, 17506, 48164, 35632, 24251, 2686, 38577, 30738, 41198, 5964, 23177, 14557, 14667, 50141, 19658, 43799, 61716, 18952, 160, 36398, 55440, 30682, 38331, 32779, 13057, 15449, 30275, 42518, 17021, 8521, 45137, 48530, 18802, 12995, 19211, 60753, 43015, 38174, 31779, 25221, 32766, 48740, 42284, 15551, 53602, 61165, 12895, 37931, 12701, 19718, 54190, 54844, 44650, 60902, 12829, 9760, 13792, 4566, 41137, 31127, 49677, 2292, 37118, 18660, 23991, 28865, 42003, 48189, 60178, 63828, 57690, 57925, 53965, 43436, 65037, 13920, 17198, 48420, 1341, 12757, 20359, 37212, 64093, 30193, 54525, 25313, 7157, 2237, 2739, 45131, 12125, 60846, 17126, 51223, 65020, 58304, 63506, 55405, 28471, 21580, 28732, 15628, 23335, 41381, 13929, 50361, 61190, 26935, 22592, 12684, 52660, 11933, 52049, 54690, 36358, 37267, 51799, 48778, 3722, 11807, 54153, 28750, 58834, 13171, 27447, 41226, 7899, 3664, 13608, 18169, 49761, 2044, 34513, 54941, 47681, 63909, 49564, 4046, 16505, 55447, 44016, 45441, 40668, 61371, 64674, 23707, 57367, 15587, 28141, 16574, 57423, 57345, 8860, 3202, 54334, 51149, 30920, 13239, 8001, 48446, 33843, 58375, 54917, 36788, 12105, 64134, 17892, 1137, 27623, 7951, 40467, 49720, 8312, 45454, 23932, 37326, 9193, 18880, 50982, 43162, 41098, 53920, 37940, 45649, 1267, 59604, 20686, 863, 40131, 51043, 56496, 18759, 19899, 6596, 61510, 52040, 11810, 28982, 20939, 56942, 622, 20689, 46260, 9672, 31216, 47905, 11272, 47738, 40106, 9121, 46620, 18114, 52865, 24073, 26974, 7177, 37054, 36683, 40529, 62871, 8550, 55417, 44052, 20155, 63010, 52204, 25080, 44130, 17820, 19317, 13979, 30391, 42280, 23645, 16366, 39790, 27935, 51339, 12812, 14170, 36536, 51931, 41757, 15915, 51345, 51071, 53195, 58001, 15093, 14598, 35077, 28509, 21077, 20385, 35403, 10121, 46689, 43705, 6742, 48734, 27706, 4619, 47918, 45718, 6713, 40613, 46776, 23083, 51056, 20719, 48679, 26778, 52770, 62312, 19268, 51613, 18347, 21220, 35536, 64087, 20116, 30894, 3878, 38985, 27741, 12983, 7152, 42555, 31242, 47405, 32294, 1727, 62973, 48206, 54378, 42221, 71, 44678, 32690, 6674, 20017, 14570, 22843, 26640, 3248, 29225, 28024, 1434, 36592, 58640, 38754, 58179, 28430, 56210, 62647, 27326, 44297, 53526, 30223, 49571, 17861, 33677, 35689, 43671, 28587, 63224, 48755, 53698, 44301, 58319, 1737, 4774, 46662, 11631, 20599, 26418, 53473, 18963, 60576, 31305, 32220, 64823, 23977, 32465, 854, 9097, 14858, 8880, 27562, 8400, 12382, 43834, 64350, 62237, 5399, 5234, 26239, 61433, 1297, 12134, 7337, 53363, 6559, 37748, 32888, 33566, 14746, 43744, 5309, 46336, 61778, 30467, 11809, 15840, 50696, 23567, 7531, 7051, 15179, 36404, 37061, 26661, 6586, 22327, 50198, 62629, 17815, 54820, 24180, 54857, 34808, 54658, 49065, 6690, 54541, 54554, 58675, 30695, 56513, 63987, 53495, 19721, 26209, 37404, 58389, 794, 32881, 10285, 36538, 24630, 1053, 60407, 62011, 27460, 40932, 30852, 13531, 37519, 53040, 64080, 54629, 29730, 7260, 26437, 295, 33625, 20223, 13310, 51279, 25518, 41386, 36714, 4514, 58437, 26140, 44978, 38546, 10759, 22564, 22275, 24265, 37290, 52563, 4223, 29469, 47460, 34978, 48684, 48862, 24326, 59684, 63690, 25561, 7121, 53744, 27019, 31372, 48951, 17083, 47478, 1594, 18669, 33712, 25879, 53988, 56817, 60060, 41915, 25976, 39123, 50111, 36558, 14853, 50757, 35856, 12605, 22989, 38762, 24405, 11213, 52807, 37317, 59183, 40525, 6723, 51168, 43603, 40471, 33328, 13734, 11117, 26798, 44201, 60801, 17072, 59009, 54472, 38854, 14771, 9566, 33588, 35692, 16940, 19417, 9420, 25451, 18895, 45128, 11519, 32365, 12387, 39751, 59622, 22265, 18129, 45272, 16435, 40600, 7551, 14013, 25257, 20546, 15187, 32832, 17292, 37093, 26200, 627, 41175, 40573, 44501, 17561, 60781, 51281, 47039, 51040, 63245, 38955, 15240, 6553, 64299, 19394, 42477, 29455, 37347, 23186, 27765, 227, 19937, 33323, 42906, 59926, 14061, 1186, 23976, 53571, 44347, 22978, 24286, 2543, 31568, 62664, 15386, 20852, 57028, 23264, 26020, 15468, 33710, 33807, 2314, 25347, 12236, 57430, 49892, 45466, 43978, 12252, 4796, 61068, 56759, 11087, 58663, 64808, 25911, 8564, 64868, 31279, 9653, 25588, 30405, 62082, 6706, 25004, 61378, 63123, 11517, 32122, 48324, 30158, 8953, 40854, 2604, 35796, 43742, 38730, 55528, 23382, 37807, 46493, 56247, 51416, 469, 52235, 42443, 27451, 33079, 21267, 35618, 52492, 55109, 23918, 60759, 33572, 51278, 21946, 42918, 53661, 60323, 1843, 204, 55429, 42102, 9679, 64570, 2277, 42448, 50998, 28498, 59737, 47240, 56183, 10471, 4575, 62270, 58099, 47372, 14174, 60293, 64803, 46409, 55120, 18227, 55806, 57282, 5659, 20470, 46051, 30088, 34599, 65337, 57089, 4926, 46553, 23548, 16191, 19224, 37060, 53762, 58338, 8908, 58819, 18761, 46312, 20510, 9031, 13527, 65338, 16152, 58749, 6918, 28715, 44889, 18576, 58497, 58596, 20920, 10773, 56974, 37772, 42004, 19951, 14037, 6712, 54791, 58611, 26755, 65396, 48345, 40905, 64505, 45407, 29139, 29506, 60127, 47108, 36232, 8475, 6304, 31592, 18513, 3936, 12800, 5856, 47761, 12915, 20816, 50088, 19141, 55369, 3495, 36493, 23343, 5750, 60449, 34012, 41524, 56846, 47598, 10054, 7740, 21620, 5724, 30110, 30572, 42275, 19871, 8579, 23292, 19776, 17925, 47609, 63203, 25466, 20701, 19732, 4674, 50467, 7334, 50407, 26859, 4405, 8882, 19325, 63591, 14399, 1445, 19052, 16677, 55793, 47299, 11068, 27067, 65259, 25586, 7448, 47537, 27589, 30390, 15276, 1783, 17084, 54299, 35542, 48514, 26313, 43555, 33638, 17157, 22986, 48966, 60542, 57851, 36224, 59353, 59400, 56071, 7689, 58145, 1672, 60800, 7483, 25180, 63888, 27378, 38263, 43870, 32158, 36350, 3168, 3148, 31618, 36523, 24125, 58396, 27798, 26861, 12604, 45224, 23948, 46942, 44074, 61978, 39829, 26193, 28364, 20604, 60403, 42689, 40069, 7238, 50455, 7776, 26606, 6931, 41655, 5549, 29330, 2306, 55500, 5096, 30515, 11869, 32608, 8853, 32696, 62112, 7714, 26249, 13876, 18343, 14849, 28563, 8784, 58665, 10555, 51890, 11730, 20343, 15132, 43571, 49591, 826, 23752, 33005, 64402, 27410, 57713, 1121, 13621, 30103, 26402, 14662, 44489, 8224, 62471, 55115, 48576, 28096, 52438, 35282, 6026, 6425, 63075, 25431, 41172, 19976, 14268, 32848, 47437, 23718, 44942, 41923, 55727, 53780, 17377, 3232, 24165, 60004, 48145, 21969, 44275, 29886, 23070, 5351, 1179, 15215, 2770, 35229, 21964, 20144, 65008, 3509, 21597, 14256, 7488, 12291, 14987, 55622, 38490, 23789, 14216, 37544, 19875, 45860, 7000, 26699, 32601, 6498, 39736, 54325, 25577, 51721, 30498, 26809, 1652, 63877, 13114, 12808, 193, 38721, 29123, 26160, 40966, 26627, 46109, 20683, 38291, 31703, 8600, 51896, 39804, 27659, 31240, 2366, 43099, 23046, 20277, 7397, 47378, 16075, 50416, 26290, 31078, 64790, 28433, 44461, 28655, 60979, 4042, 23198, 53742, 60625, 11230, 61818, 60107, 6722, 58122, 6152, 38454, 21252, 2440, 30521, 59471, 38846, 31081, 35704, 27863, 33358, 56388, 56143, 57794, 21493, 34791, 29838, 4867, 17103, 31501, 16535, 37122, 38320, 537, 55938, 30380, 26257, 57684, 58698, 61325, 10399, 14043, 37077, 52647, 9514, 56985, 61023, 46626, 4323, 11613, 61780, 46574, 11490, 13589, 43985, 16610, 52388, 19170, 39798, 45905, 27250, 33978, 55629, 16225, 34496, 25033, 57930, 28614, 14425, 55043, 53452, 48931, 40347, 4030, 52285, 63520, 16860, 13266, 58331, 15670, 46196, 28529, 12967, 36983, 56907, 1607, 19908, 13405, 61533, 34522, 19551, 51687, 59671, 30962, 57668, 31933, 11092, 40521, 13515, 21009, 27912, 55721, 35028, 63695, 11434, 5019, 7430, 7817, 25569, 19398, 26502, 47005, 50192, 18547, 59959, 44310, 61311, 33155, 36769, 40962, 56665, 52140, 40190, 25302, 10305, 34030, 23361, 55645, 20762, 16374, 3596, 5607, 63450, 3680, 21329, 14573, 22789, 36200, 21146, 12416, 41699, 17743, 44550, 65091, 15683, 53992, 33831, 63354, 30564, 809, 49739, 59735, 61221, 34913, 37877, 25835, 52302, 55917, 28922, 60400, 35400, 23397, 10536, 14325, 54705, 41811, 10822, 14212, 63790, 27905, 42064, 18778, 50834, 2426, 8501, 29441, 18492, 46557, 1982, 31396, 51693, 22769, 28769, 4237, 13219, 59860, 11855, 46460, 11493, 14712, 42316, 127, 29532, 64774, 27986, 43239, 14873, 20804, 63080, 62637, 52141, 48548, 10268, 28612, 10967, 37988, 63318, 11947, 42623, 14009, 64704, 36330, 52652, 28823, 55523, 8780, 4115, 29706, 4286, 24249, 50906, 23156, 8390, 64502, 57166, 44385, 47635, 59913, 61180, 18556, 7383, 14509, 52487, 57298, 57023, 2749, 65148, 64317, 59417, 7868, 15445, 40491, 31797, 29006, 40628, 2022, 16719, 3412, 55135, 64963, 60640, 60443, 27575, 37656, 35152, 27101, 29517, 51807, 32262, 18914, 33427, 23373, 34003, 43625, 49935, 46914, 18368, 56219, 24682, 55537, 46854, 21661, 41071, 33521, 48208, 65027, 62977, 62157, 64491, 15310, 6409, 26578, 36381, 5353, 20228, 22808, 54336, 4888, 13024, 2249, 9663, 7344, 31368, 20613, 29412, 47655, 32289, 41260, 36829, 55382, 28968, 376, 13432, 34531, 30130, 10721, 63259, 10215, 2021, 8720, 14193, 7021, 11535, 63949, 32876, 57530, 5529, 5419, 63694, 18925, 8861, 36682, 38614, 3666, 63671, 38910, 44771, 7339, 333, 59427, 48647, 58354, 17528, 39893, 7097, 6890, 52727, 13263, 42927, 40144, 3499, 16710, 48963, 64315, 27434, 19590, 20673, 6217, 8851, 44553, 7596, 48221, 27142, 65197, 20242, 26395, 10145, 337, 12032, 23499, 32328, 16949, 27290, 6247, 35449, 57656, 27779, 33756, 46241, 32403, 60268, 37362, 33874, 10049, 1898, 30791, 12405, 37610, 61827, 40038, 54743, 61451, 20149, 64337, 48856, 61201, 13924, 47876, 25663, 15406, 59203, 38643, 42886, 59191, 2658, 20151, 8608, 44195, 46700, 25037, 52389, 39312, 20842, 6762, 20776, 64141, 10472, 39764, 50535, 59939, 21686, 29402, 30366, 43598, 3236, 20764, 45962, 46462, 11567, 4670, 18305, 65355, 16410, 18088, 46841, 46145, 64876, 54673, 19991, 55983, 9267, 43266, 36243, 29107, 40220, 59760, 63041, 62346, 37820, 9871, 52171, 21160, 61594, 11632, 18687, 2938, 52687, 32794, 11541, 21324, 50153, 26321, 36220, 37289, 17689, 13270, 65232, 59504, 2437, 8217, 22455, 35087, 36853, 64924, 7854, 56922, 41201, 45227, 35202, 63302, 56384, 44717, 64934, 29524, 22358, 17236, 37785, 55670, 912, 49606, 54375, 36437, 2830, 33327, 28733, 14184, 14500, 47381, 65174, 16213, 11303, 28174, 10212, 55588, 63193, 31051, 54466, 47127, 12062, 10066, 22922, 1761, 20501, 48063, 32183, 31468, 25735, 63247, 52409, 53498, 11393, 30554, 56344, 55740, 4837, 3092, 12447, 31594, 31721, 27523, 56589, 43463, 38222, 50857, 50614, 56841, 16974, 53394, 60990, 56597, 48939, 37805, 305, 33023, 39525, 9250, 16771, 51825, 16094, 59823, 35343, 39615, 23278, 13491, 39964, 19999, 64843, 51210, 60075, 5940, 48497, 57922, 36410, 61060, 5247, 55543, 10351, 6455, 52992, 12049, 11010, 9530, 25145, 36249, 52220, 6129, 15410, 25813, 65353, 47589, 50670, 40001, 17364, 31631, 11320, 2886, 29464, 2964, 25509, 62852, 27829, 4425, 54438, 48784, 47366, 60289, 2740, 6844, 4701, 63666, 51798, 33393, 45362, 47451, 37806, 30916, 16086, 7328, 53789, 38055, 14429, 14578, 13615, 34524, 47146, 53031, 32609, 43852, 54661, 11629, 27409, 55899, 10424, 27576, 44198, 8634, 22901, 53654, 24433, 59215, 57199, 27980, 38623, 17340, 12485, 15416, 15488, 14691, 62778, 30741, 7167, 37074, 32190, 61071, 11247, 32136, 41970, 14409, 4828, 19977, 40047, 23715, 16777, 5116, 11488, 25325, 47650, 35448, 6754, 38365, 54978, 18400, 62817, 27343, 9399, 46223, 17371, 51949, 5980, 64825, 15456, 37720, 35222, 17852, 64032, 47452, 3062, 41580, 26550, 2688, 39125, 45403, 59977, 10855, 17233, 39679, 45439, 34333, 58588, 46384, 27345, 9703, 56983, 30297, 42250, 27223, 6123, 65268, 23121, 38229, 31398, 9929, 29367, 27395, 31967, 45743, 9446, 6580, 30065, 41786, 1993, 4639, 55057, 49266, 13156, 60501, 10868, 58343, 38829, 41995, 55136, 46213, 62316, 25075, 24466, 20324, 57937, 25725, 64270, 50458, 36910, 17776, 24608, 57860, 45323, 14489, 31940, 23731, 25885, 51610, 11089, 12100, 1809, 54277, 20312, 16089, 36898, 13221, 876, 14821, 44477, 59199, 43922, 39421, 42051, 43352, 18590, 24986, 51010, 8261, 40272, 36610, 41615, 19942, 53719, 25825, 41737, 17835, 7529, 64051, 43806, 5068, 38674, 29181, 18882, 48935, 22713, 27716, 29947, 44604, 51601, 62618, 64458, 65097, 22855, 40860, 64098, 20269, 12647, 54553, 28962, 7404, 862, 45124, 15872, 28016, 8174, 57853, 7990, 23747, 52620, 9870, 38252, 25409, 8952, 17559, 55913, 29054, 59441, 2735, 12259, 54447, 65471, 2178, 10354, 40679, 60386, 58485, 33466, 39971, 15503, 17347, 47902, 55240, 51586, 995, 36959, 17399, 63504, 55782, 55549, 16311, 614, 16713, 29297, 30807, 61662, 28675, 50069, 23711, 60524, 42950, 23506, 15082, 121, 50991, 29426, 2194, 9458, 40135, 16178, 11802, 38188, 34460, 8197, 9904, 27489, 63983, 33001, 53903, 51871, 60275, 48370, 61822, 53477, 11811, 24456, 16842, 12531, 13384, 25493, 9512, 44089, 6840, 4748, 26652, 49681, 46925, 65361, 10982, 29164, 18512, 14148, 52303, 46128, 46649, 35137, 64654, 24580, 19352, 12627, 13890, 3557, 64031, 59046, 47073, 32275, 60582, 1838, 2855, 22703, 62815, 18403, 11763, 10340, 10452, 58853, 49885, 33728, 53845, 52366, 62420, 4244, 56048, 24218, 30367, 30734, 18394, 932, 46885, 31061, 50021, 21063, 34433, 28686, 61623, 18595, 23398, 35301, 58539, 10609, 21535, 48052, 16637, 22553, 43376, 52525, 58835, 9941, 28847, 63534, 18408, 42345, 41666, 1794, 30999, 64771, 47932, 50997, 35171, 5670, 42217, 8434, 58033, 39585, 20739, 36075, 65442, 50559, 3430, 53481, 22457, 61196, 1394, 49468, 35895, 13727, 5493, 16847, 55103, 12545, 44529, 55587, 63198, 36173, 29103, 59809, 5807, 4415, 6086, 36918, 48129, 57419, 49397, 1840, 56530, 15364, 50395, 4160, 20124, 6453, 61601, 18526, 41003, 3004, 7463, 5997, 42151, 64390, 32503, 33471, 3016, 43601, 55316, 693, 39242, 50070, 37626, 29767, 1194, 1139, 6838, 57443, 29508, 64138, 51844, 29428, 27396, 24631, 58680, 20911, 9675, 13085, 23380, 13793, 7508, 36602, 1200, 42913, 56265, 37104, 40420, 16993, 23761, 45495, 39259, 42784, 14674, 6660, 43443, 19754, 24161, 58664, 60772, 38343, 12776, 61469, 12018, 8237, 18069, 36886, 5487, 44610, 45056, 12926, 37997, 28425, 29864, 49157, 12213, 17981, 5169, 19716, 492, 11476, 55248, 28427, 30451, 49374, 62081, 39367, 57604, 50132, 4173, 63218, 63564, 39468, 18385, 56822, 55164, 29765, 61494, 41233, 43673, 60209, 22949, 27820, 46388, 50482, 1829, 62849, 22827, 58519, 46711, 11423, 31308, 37698, 41822, 56126, 42428, 64376, 54085, 63593, 23052, 11985, 26542, 61568, 11794, 18208, 9623, 45714, 32033, 64990, 30248, 64151, 59925, 64063, 17465, 61526, 35486, 40320, 35218, 58647, 6874, 7673, 23388, 47455, 43394, 35310, 37468, 60179, 37481, 50023, 56091, 25554, 25877, 45525, 32656, 14910, 47989, 28896, 52942, 5178, 64056, 31690, 65376, 24586, 21235, 19073, 5435, 14754, 25954, 63325, 3328, 59758, 37328, 57629, 40361, 51420, 41500, 37590, 4922, 26824, 41194, 14377, 35109, 41334, 44856, 26201, 54937, 63386, 24149, 52426, 54150, 56896, 42341, 6420, 26988, 45186, 45457, 39027, 56657, 30960, 55304, 64992, 42263, 40443, 21622, 4782, 45276, 7191, 23665, 21675, 15425, 17427, 3374, 41512, 63254, 48020, 64503, 14995, 21386, 56623, 42671, 64042, 58471, 46197, 53979, 1644, 46739, 41162, 30877, 7563, 48146, 17694, 9495, 26916, 38050, 1365, 58535, 7659, 3253, 1254, 10916, 30545, 43800, 61099, 6458, 34852, 35521, 12260, 22501, 30362, 64742, 10397, 39717, 7319, 28150, 62170, 3655, 22432, 43149, 13874, 5006, 62632, 37462, 10475, 60072, 58587, 50947, 43618, 5624, 51718, 31371, 25346, 5364, 26970, 13640, 64177, 48720, 57708, 44075, 25436, 39000, 58498, 11792, 26805, 58318, 48358, 1598, 16694, 64155, 33369, 57257, 45919, 13486, 55691, 6036, 2621, 52510, 28965, 23295, 45372, 34441, 16904, 33424, 17936, 34120, 45877, 27094, 58174, 2149, 31642, 8770, 36122, 43724, 43740, 19746, 14519, 26586, 15562, 16859, 7709, 11690, 39818, 39543, 38156, 31889, 6884, 2729, 49524, 26972, 28272, 29014, 61598, 60345, 17537, 5464, 60712, 48565, 64118, 25386, 39332, 58608, 7657, 23542, 58361, 51943, 40079, 63759, 60401, 17836, 8026, 63320, 35564, 55029, 32798, 15983, 7905, 46325, 52888, 58481, 61898, 56029, 22374, 47895, 8405, 21715, 49324, 26763, 41136, 23826, 54458, 31625, 19249, 2751, 13513, 55748, 22195, 45365, 26665, 2215, 48456, 7118, 31450, 11601, 24181, 58762, 54647, 41088, 61733, 65102, 31660, 18980, 30188, 32277, 62963, 53089, 17579, 49201, 63950, 16001, 56244, 62604, 18587, 61730, 4038, 60103, 39194, 58953, 17287, 1525, 11084, 62595, 40960, 21763, 13371, 1755, 63890, 13886, 39844, 33672, 16254, 53269, 33581, 60975, 63500, 37842, 43428, 35108, 2875, 26508, 35240, 11224, 12379, 60717, 12173, 22776, 50753, 63832, 11334, 27376, 42595, 37975, 58600, 21820, 32963, 14232, 31926, 34485, 56005, 55620, 6111, 55133, 49222, 13463, 11634, 57584, 43778, 32521, 877, 12541, 18407, 47374, 5071, 37525, 997, 41529, 54752, 30141, 63287, 43647, 17626, 45310, 38462, 24561, 59282, 39599, 15498, 24260, 22807, 8984, 32425, 17100, 15769, 54474, 57143, 50263, 48653, 8576, 14734, 19037, 50261, 22326, 3845, 37384, 15808, 43689, 6701, 46836, 19267, 60063, 35565, 40708, 54518, 36463, 29719, 58402, 53678, 16953, 5417, 4264, 56205, 32138, 58463, 17825, 9618, 60702, 3673, 31464, 1272, 16936, 26423, 4687, 60281, 49653, 38220, 29590, 8215, 41384, 5971, 28763, 9058, 47190, 48412, 26871, 58359, 29335, 6275, 10117, 61591, 35977, 63384, 56307, 5653, 28355, 27282, 59255, 16226, 2223, 2386, 49527, 28466, 4137, 18918, 5733, 32121, 47212, 18095, 1017, 21380, 17356, 50697, 25635, 37771, 39840, 3484, 37648, 60674, 19420, 30048, 1834, 43795, 25685, 51691, 24371, 30126, 40259, 32080, 2879, 18744, 56222, 39124, 3047, 11924, 42014, 8859, 12620, 26445, 39365, 2723, 47167, 3411, 49943, 27929, 19435, 45755, 38146, 3734, 46253, 35415, 58327, 7877, 32021, 1649, 31751, 19571, 15484, 30273, 29666, 41689, 62180, 10907, 28369, 8274, 8175, 48710, 20844, 28855, 13160, 22294, 31784, 50420, 7171, 51847, 38887, 37848, 18974, 21155, 10746, 61462, 51470, 17457, 61630, 33124, 58657, 5741, 12954, 21154, 62506, 19255, 43184, 8801, 19819, 18792, 61019, 32483, 41072, 56947, 61663, 64230, 49822, 55282, 20848, 45574, 9095, 36721, 32129, 11173, 49779, 52855, 50442, 24183, 37768, 46014, 30056, 30806, 12794, 6006, 11323, 33782, 37321, 21343, 36817, 48190, 63745, 30376, 44120, 49704, 26689, 52702, 52907, 8370, 39815, 44040, 14452, 45450, 52352, 21568, 23922, 52637, 29693, 62950, 65286, 62541, 35964, 34026, 32654, 25218, 60398, 61091, 40451, 44073, 56333, 6356, 63138, 41704, 58696, 61076, 33724, 7380, 25366, 40994, 26698, 14697, 47276, 11791, 56834, 40387, 10702, 29245, 35524, 16370, 62013, 33772, 40011, 24544, 24219, 18701, 33624, 42147, 34580, 35709, 32906, 46718, 23666, 28381, 10821, 27602, 8532, 46698, 8995, 23493, 54715, 12295, 63215, 47166, 64574, 10706, 890, 23097, 39979, 26555, 29630, 30584, 55311, 3351, 29106, 13575, 46597, 21213, 33643, 13011, 53983, 20226, 7917, 19455, 33166, 51171, 16132, 8031, 62152, 96, 14789, 3573, 12539, 9037, 33053, 59890, 17943, 38842, 8176, 48160, 46160, 49672, 21093, 9161, 20663, 49926, 61369, 35673, 12678, 25148, 62441, 13681, 41017, 60521, 5171, 58271, 15431, 11478, 40803, 47730, 64592, 1492, 9212, 32111, 62025, 63085, 57245, 54811, 58332, 22307, 35831, 40431, 8614, 16656, 18397, 14790, 2170, 929, 10166, 48264, 34883, 40499, 65177, 51425, 8148, 23612, 43122, 55871, 8039, 61468, 11775, 49274, 62360, 55538, 57162, 54371, 24642, 964, 27212, 8964, 10454, 485, 55444, 31452, 38443, 53837, 16290, 41173, 23987, 52189, 10775, 4446, 32419, 5887, 29423, 61729, 17535, 12021, 57498, 4094, 55823, 47643, 2338, 17862, 30452, 3795, 58135, 15642, 27543, 48613, 29282, 48952, 13102, 14165, 23319, 1206, 58, 14811, 29674, 48546, 49948, 42007, 10546, 63279, 46778, 34961, 52694, 27963, 61194, 2279, 14774, 59983, 15734, 42613, 65315, 34792, 43746, 50447, 16218, 64012, 40188, 16440, 17773, 15492, 37849, 40249, 65075, 9054, 3199, 11536, 46834, 31200, 61343, 16383, 4801, 17434, 11418, 25216, 26602, 43686, 137, 28934, 23481, 1775, 28292, 16815, 48105, 35733, 17663, 56763, 34493, 59344, 20829, 64232, 37376, 37397, 1764, 35027, 62898, 46443, 22578, 9952, 32203, 11571, 59308, 22716, 51892, 21960, 38901, 51126, 29048, 3134, 203, 15163, 52063, 18661, 30229, 60216, 47134, 61162, 11514, 6749, 51781, 48342, 5042, 55809, 44944, 162, 38125, 35669, 13339, 35433, 61041, 28318, 36753, 48809, 45509, 32016, 39685, 44369, 12738, 20948, 5683, 39567, 54020, 48083, 12650, 8467, 14787, 36130, 44565, 47948, 60379, 52319, 37358, 12248, 64939, 20444, 59898, 38849, 12570, 19380, 46664, 33557, 2285, 26837, 47394, 18953, 40317, 26382, 60226, 5224, 9992, 6483, 63358, 25766, 23066, 34683, 46809, 49929, 62131, 38918, 60868, 59520, 24920, 24844, 19939, 55915, 62010, 29044, 23317, 53054, 16872, 47271, 61039, 30803, 9395, 29265, 23557, 56484, 2287, 14917, 23743, 845, 25457, 52720, 25383, 31329, 37561, 30860, 45271, 39029, 54868, 12138, 6611, 6724, 52771, 41369, 12078, 18078, 26486, 22177, 50760, 49393, 60937, 1983, 7804, 38350, 4040, 23226, 27588, 8871, 27632, 36902, 52834, 18502, 24828, 46722, 42171, 63456, 57355, 19174, 58370, 46932, 49242, 52895, 7206, 57056, 43696, 2818, 36860, 10481, 38935, 4935, 56990, 3285, 10233, 13159, 3889, 5509, 2726, 64866, 15612, 64196, 13579, 17613, 1656, 37051, 63535, 15885, 18164, 52218, 63941, 35585, 58642, 2871, 12440, 17651, 56867, 19402, 30485, 54852, 1301, 45215, 65026, 42862, 55514, 12734, 61445, 59360, 3559, 46797, 21197, 61680, 36019, 14900, 4442, 26645, 12346, 17570, 6005, 290, 32341, 1639, 6463, 38943, 23531, 14950, 20895, 35426, 51765, 45619, 20136, 34145, 48287, 57292, 63795, 4033, 9561, 17801, 4503, 27156, 12688, 475, 64955, 15233, 14435, 30192, 25452, 11114, 18574, 49888, 46405, 61702, 41266, 26734, 16417, 4507, 27334, 7734, 18485, 12979, 518, 44583, 3422, 40177, 45125, 64998, 55269, 15705, 47425, 46446, 21775, 9809, 26117, 5798, 22032, 36553, 48488, 58964, 12642, 35509, 12911, 6548, 53994, 31572, 14352, 4130, 46140, 28012, 39882, 22107, 14806, 9931, 54116, 55499, 14408, 36709, 60132, 17700, 59648, 57263, 39142, 23142, 6061, 50528, 4724, 65229, 8109, 2927, 3007, 2045, 8832, 30122, 33885, 31146, 28662, 8422, 64306, 63115, 65415, 32535, 27887, 62937, 51526, 56180, 32146, 6412, 34923, 25598, 52539, 2155, 21435, 43197, 31870, 47354, 50872, 55314, 42481, 20337, 30850, 61849, 35776, 64705, 51123, 26680, 60333, 32865, 6192, 9540, 28476, 39109, 53919, 22677, 45243, 9442, 60096, 19262, 60791, 51396, 38977, 37664, 5616, 30154, 42967, 44000, 55156, 49239, 58185, 44325, 8137, 41391, 31150, 36271, 3394, 17038, 4373, 39578, 15896, 13675, 6256, 50517, 27224, 25616, 26446, 22039, 45352, 9385, 39444, 57084, 14517, 10404, 39386, 10742, 31766, 2411, 42713, 65400, 27400, 7506, 14487, 29127, 58102, 39888, 61744, 59439, 5490, 27646, 14585, 15249, 57877, 33776, 12037, 45258, 334, 28528, 56435, 31246, 9266, 46958, 54179, 18214, 1027, 23251, 64512, 11496, 59899, 59919, 23401, 43226, 3117, 50881, 18144, 15785, 23227, 42809, 46532, 32390, 15555, 2036, 58793, 7179, 48612, 9553, 30929, 4849, 14972, 42407, 58850, 38873, 13404, 44646, 37139, 32442, 48430, 17355, 16391, 17410, 23386, 36942, 64156, 33041, 41486, 19729, 45510, 65111, 42032, 17929, 54996, 33312, 2182, 28885, 28493, 61966, 29099, 25943, 60032, 51344, 8946, 41007, 18703, 30315, 19554, 15773, 41744, 676, 12479, 9410, 32358, 3041, 53342, 2802, 11414, 37916, 52589, 63595, 14101, 10419, 33256, 41874, 6995, 7111, 23806, 57480, 3325, 29931, 7656, 60630, 6240, 36940, 17315, 13815, 18844, 36915, 40820, 38061, 65413, 59636, 16819, 36645, 61518, 37261, 23038, 28519, 63731, 32364, 52511, 26447, 29887, 51581, 28516, 9400, 41540, 42100, 25796, 49986, 43513, 5595, 18345, 17711, 44855, 39919, 3568, 45437, 44495, 12303, 25062, 49813, 36633, 48171, 58196, 46890, 27034, 50448, 60261, 12774, 58107, 4636, 23088, 60195, 22539, 20538, 40936, 24486, 52919, 42686, 30907, 54873, 24159, 37726, 419, 7950, 14466, 54187, 44789, 42144, 30723, 15427, 50098, 47367, 18323, 61899, 967, 11346, 7143, 14922, 2491, 30635, 21841, 27488, 59938, 57246, 22443, 47490, 6331, 15004, 2683, 23179, 36393, 39250, 39005, 481, 53496, 28501, 16512, 45368, 46757, 21048, 26077, 48499, 5519, 58721, 2967, 7515, 9078, 3794, 8779, 63933, 29639, 10737, 59940, 12665, 19062, 16569, 32985, 24047, 31755, 57247, 28642, 2797, 11165, 44836, 31399, 45951, 51, 50937, 1285, 25712, 18848, 4466, 15859, 3685, 57631, 27730, 7578, 19006, 32591, 24090, 56133, 17771, 19505, 39132, 6246, 52051, 31828, 32389, 33103, 18536, 42192, 14716, 43439, 38671, 61703, 59345, 1319, 41022, 24158, 11788, 59107, 60469, 33309, 17437, 8345, 26064, 16337, 45918, 64591, 45465, 32934, 49336, 65384, 15067, 36239, 50311, 39693, 22765, 51277, 51361, 52375, 39784, 22223, 1183, 47958, 51773, 17660, 18138, 18730, 32461, 34037, 61193, 20756, 58054, 55167, 13192, 39637, 39313, 64265, 51092, 2073, 42136, 32165, 31262, 8896, 15008, 32692, 62903, 65072, 41273, 14049, 17888, 31588, 53856, 52994, 20933, 61245, 64364, 50939, 36835, 33339, 22629, 9720, 566, 15487, 53009, 3607, 56821, 43292, 55023, 41023, 44342, 59385, 65515, 2569, 42080, 43, 14064, 29311, 47373, 56125, 25424, 25936, 37327, 56557, 47465, 7649, 50661, 64022, 45065, 19542, 16802, 10682, 56158, 55279, 55953, 33352, 11464, 2301, 59875, 9353, 11281, 12703, 20398, 16661, 7357, 25458, 1654, 9163, 34750, 42944, 42225, 27704, 18838, 4903, 16870, 24160, 22064, 61596, 43396, 14431, 1041, 43068, 54433, 36938, 53901, 51349, 3403, 44640, 24954, 13440, 40129, 48000, 32541, 8426, 41441, 55113, 18057, 50523, 15268, 24438, 30444, 12841, 21791, 4216, 45075, 46761, 36468, 58932, 43797, 3901, 844, 22639, 22396, 45269, 47683, 43432, 3710, 45138, 8806, 46037, 60886, 30506, 30335, 63813, 23303, 65357, 18735, 13088, 22813, 7049, 29312, 3609, 45192, 30319, 15568, 55421, 40899, 37577, 54147, 42622, 65281, 2320, 655, 228, 54612, 58139, 13821, 6882, 19534, 20562, 37762, 35534, 57763, 28598, 61891, 28526, 11444, 6943, 22787, 58770, 64409, 1650, 37716, 14740, 54869, 61916, 39597, 57304, 29877, 59965, 46316, 55365, 58799, 19806, 63601, 32199, 33209, 39302, 28972, 19941, 7379, 5720, 48793, 5713, 11090, 25993, 11529, 33711, 60865, 40344, 27707, 44711, 6814, 28653, 14366, 31819, 61329, 23063, 43500, 13946, 3059, 3995, 36992, 32240, 27022, 5483, 25283, 51484, 9437, 64689, 47872, 49087, 3012, 49460, 10755, 10167, 43098, 3708, 5216, 41340, 29015, 3377, 9782, 43727, 58930, 4977, 15025, 15605, 18787, 45376, 48577, 53524, 18200, 40267, 35892, 22394, 55388, 33179, 61403, 63163, 50309, 22824, 44117, 7932, 29483, 19032, 51002, 12129, 4650, 56800, 43900, 21459, 11340, 9533, 57163, 38139, 49974, 49549, 8632, 17270, 25609, 4829, 9971, 63232, 25266, 34758, 61496, 44854, 58765, 58808, 63106, 3812, 49665, 47202, 31427, 51306, 65380, 17216, 57305, 56849, 59376, 60908, 7159, 47916, 8724, 37585, 7746, 51946, 23029, 43319, 50808, 48544, 34722, 1052, 56988, 37691, 52503, 24865, 17159, 53397, 62343, 42662, 12569, 40323, 60944, 7781, 41710, 52759, 25987, 5088, 5093, 7686, 61811, 12292, 61118, 24854, 30615, 36071, 60222, 1620, 26797, 12635, 45773, 29712, 13142, 42405, 22744, 32411, 58737, 10620, 30413, 64859, 54002, 36699, 9440, 45692, 63892, 42277, 6997, 28997, 13851, 62588, 5504, 41747, 20105, 14572, 18137, 26477, 18785, 18594, 3832, 45377, 50861, 59611, 9900, 7008, 40492, 21705, 35420, 4576, 5141, 31750, 62838, 41541, 16427, 10712, 49280, 24691, 19241, 1698, 57727, 36975, 16693, 61603, 30369, 18177, 64313, 229, 25138, 51796, 59570, 11693, 25460, 59087, 21889, 6581, 34635, 42788, 27524, 40987, 41619, 4343, 49828, 2742, 8751, 65272, 45704, 23786, 19171, 10779, 14794, 4747, 37759, 52544, 46477, 59101, 59616, 20793, 14947, 54965, 51214, 36833, 33705, 55251, 65047, 6146, 42077, 46913, 62111, 29964, 56370, 23735, 15476, 51820, 36743, 45680, 29844, 19230, 1248, 13596, 50435, 4270, 56081, 26229, 12118, 25687, 23465, 15432, 46300, 41397, 63565, 346, 44726, 42162, 11491, 24026, 22698, 20730, 47222, 7584, 52663, 17338, 11881, 43484, 22858, 62968, 45394, 28947, 17008, 10878, 33590, 45548, 1220, 1894, 64861, 58317, 11386, 7685, 19379, 47235, 4267, 14006, 38097, 13426, 20130, 65153, 58115, 53760, 10171, 61754, 35561, 60580, 32682, 53653, 58807, 49565, 25834, 21031, 30276, 34919, 45817, 51259, 22312, 61875, 63299, 28187, 11776, 18534, 41511, 38332, 37379, 60978, 48022, 10979, 8656, 57030, 35518, 25192, 62143, 22570, 39755, 47649, 21362, 61605, 3241, 380, 37607, 20597, 51197, 58754, 17728, 59448, 1855, 33207, 3491, 23441, 55097, 26880, 61204, 33367, 52754, 57913, 1065, 22522, 1273, 30836, 16049, 40123, 53379, 15418, 51671, 63935, 1099, 4914, 43949, 14123, 64875, 19401, 46926, 52502, 57951, 28824, 52150, 38995, 44487, 60833, 19805, 33292, 21532, 20511, 17317, 52793, 12495, 46261, 52415, 54506, 16336, 5845, 13655, 24018, 11260, 55982, 32814, 63998, 13614, 17329, 4081, 20495, 56578, 8007, 57456, 3675, 50032, 56096, 15097, 35107, 20569, 31298, 50498, 49799, 48101, 5293, 8516, 27242, 17560, 34187, 29533, 21311, 29997, 50603, 21059, 62371, 3034, 54573, 1168, 48201, 44086, 53305, 16876, 49736, 33812, 42141, 64236, 35357, 11639, 14956, 25072, 55129, 59333, 18690, 27712, 53909, 45916, 52512, 48040, 8077, 34990, 34367, 41026, 41999, 61156, 1486, 46155, 46903, 22957, 30395, 31620, 38568, 55746, 47835, 35118, 48985, 18873, 57025, 32951, 45448, 57681, 843, 54092, 52403, 11184, 28698, 3922, 56628, 41893, 22752, 47199, 21526, 50785, 60911, 41640, 56526, 30150, 11427, 43202, 9403, 24094, 57497, 23245, 39808, 37032, 49667, 36913, 44396, 54353, 34851, 38732, 35946, 24850, 35139, 33617, 29961, 15992, 32880, 56033, 64122, 23763, 7717, 17516, 43288, 34831, 14504, 27465, 29331, 22526, 21538, 44276, 46609, 54968, 24962, 52915, 43938, 10252, 2829, 19201, 34973, 56624, 14962, 51397, 22075, 38742, 48638, 29087, 13737, 48154, 41840, 50380, 15934, 47770, 11760, 37580, 18561, 58225, 58416, 52548, 38954, 48109, 12210, 28067, 4814, 31036, 29359, 40007, 8690, 31707, 23094, 7, 47690, 58149, 26884, 51187, 34802, 41818, 19650, 59863, 35681, 42870, 9716, 55134, 805, 61979, 1029, 63348, 64920, 23338, 24311, 6308, 36828, 37885, 15580, 37369, 25854, 61472, 26207, 40703, 28165, 56954, 39319, 17211, 7017, 39584, 54245, 24345, 5561, 58259, 56212, 37150, 24820, 36756, 22450, 23796, 12870, 47752, 64308, 26860, 50094, 12753, 7408, 42799, 49977, 22890, 32329, 5742, 26926, 34640, 25963, 63122, 53740, 23760, 58650, 33050, 23476, 33083, 26245, 46865, 38046, 1724, 44268, 11206, 23828, 45460, 27557, 3843, 30901, 37783, 17822, 40724, 59434, 40513, 54120, 9682, 59946, 44365, 57324, 30084, 50221, 6171, 23140, 20246, 51440, 20406, 59228, 20346, 3520, 62663, 22437, 9699, 53599, 42195, 13378, 2588, 20112, 20853, 12484, 26232, 18828, 15961, 24054, 43279, 628, 59430, 25565, 40619, 11703, 30988, 53455, 62853, 43921, 19106, 40071, 22833, 25321, 18495, 45947, 7867, 20051, 42445, 32755, 33189, 20714, 3719, 37555, 40723, 13096, 54488, 20778, 47626, 43399, 51894, 51597, 20789, 6206, 5245, 61803, 38933, 36284, 17081, 37954, 19503, 20737, 54706, 60785, 22022, 5235, 30606, 41170, 1970, 5305, 60040, 27579, 6594, 24998, 60881, 12683, 51906, 50832, 36257, 56271, 11267, 1599, 8722, 27197, 56861, 6858, 26455, 26741, 15632, 38378, 45907, 3069, 46887, 11521, 59247, 56887, 46633, 3107, 27904, 11161, 30036, 60701, 58309, 50569, 18654, 5016, 62205, 62981, 61242, 16451, 14319, 13623, 34563, 24851, 2322, 8515, 7308, 16151, 921, 8670, 52862, 9347, 41157, 31226, 59807, 8393, 57104, 44032, 16732, 52035, 5904, 63188, 15257, 29550, 24985, 37722, 24836, 43979, 21659, 36793, 54396, 19849, 16185, 21315, 58989, 44279, 51334, 58419, 3962, 52275, 5557, 38804, 24928, 30009, 55012, 41767, 37278, 13645, 1935, 56805, 60425, 22401, 20723, 55489, 5005, 49477, 28487, 43977, 7754, 15411, 38830, 45178, 5841, 40023, 28095, 15072, 45367, 45920, 56509, 7453, 1768, 22749, 48541, 42516, 42709, 19525, 40166, 814, 39463, 43029, 37342, 56246, 21928, 10886, 27577, 36089, 1900, 58219, 42902, 16470, 61869, 53464, 39361, 10159, 47639, 32651, 18746, 7935, 6929, 880, 30975, 47180, 61257, 55677, 32894, 11570, 3063, 39220, 11269, 29275, 46349, 60816, 21886, 63135, 60142, 10335, 62432, 6787, 10111, 3677, 33611, 51364, 27036, 65432, 65164, 1124, 43903, 61225, 16868, 36382, 43325, 6606, 36102, 11312, 65410, 52074, 31397, 62829, 6648, 56207, 33223, 30428, 5808, 59679, 23751, 58970, 22605, 26360, 14215, 7812, 51401, 23336, 53188, 41713, 45823, 61111, 36471, 14808, 2799, 29213, 42617, 14681, 59888, 62062, 34480, 48450, 50829, 35703, 33406, 58285, 39662, 39278, 58045, 49386, 64587, 22158, 18771, 38909, 3467, 47211, 53100, 63836, 23456, 47264, 25439, 42833, 46529, 29217, 36113, 49088, 41552, 60271, 65210, 1299, 1011, 17365, 55637, 58792, 47412, 52304, 38295, 55925, 28710, 5983, 49511, 8251, 14668, 44014, 47637, 43050, 39241, 47159, 4821, 20442, 27858, 7634, 42536, 32616, 4946, 26279, 22882, 32940, 36151, 9251, 61104, 53160, 48898, 7166, 62562, 37906, 63804, 58800, 17476, 2421, 4679, 37897, 8704, 18578, 7948, 56003, 64645, 2944, 16237, 31220, 30676, 8510, 369, 41683, 35657, 16045, 2977, 34325, 30816, 28902, 64273, 9052, 30706, 62049, 51157, 53866, 43419, 51998, 40264, 62352, 30669, 65195, 27237, 25209, 62454, 8729, 6609, 8990, 28254, 62282, 14010, 3786, 29045, 21173, 40806, 19118, 14205, 25506, 18333, 47008, 37980, 45804, 8442, 30183, 26510, 60022, 3502, 45236, 31577, 47573, 27701, 58862, 41602, 62979, 15278, 19248, 28851, 26457, 43807, 45530, 43087, 24749, 31486, 37192, 44903, 31511, 10234, 44763, 26228, 39592, 56633, 7941, 54520, 53406, 2113, 47622, 33989, 13774, 25398, 44991, 23680, 8828, 1998, 28038, 61302, 6954, 55990, 39577, 32147, 38284, 52740, 44473, 2274, 4902, 7766, 52345, 53984, 64161, 49980, 4491, 43751, 31302, 9803, 22946, 48036, 2057, 12716, 536, 5373, 25475, 47831, 17571, 40980, 14369, 23590, 41932, 3311, 58166, 10808, 44132, 38330, 6758, 26771, 6334, 58217, 22630, 18482, 9590, 37439, 59119, 36447, 53805, 59346, 30440, 6507, 61415, 45335, 39122, 48551, 25736, 13386, 23157, 30156, 48843, 53046, 53645, 6691, 8284, 35302, 52221, 14868, 23855, 25353, 61840, 62700, 7612, 10827, 40271, 59038, 22420, 2933, 1451, 54229, 41765, 17567, 40449, 14121, 60254, 10491, 46459, 64595, 32437, 38232, 59216, 52516, 43627, 58508, 18893, 64777, 19374, 5238, 1399, 8619, 4213, 40266, 2467, 46074, 54590, 9525, 45554, 46314, 42739, 32976, 17186, 17469, 7228, 22407, 60585, 32704, 19974, 25513, 4387, 1618, 37939, 40754, 30819, 8035, 56535, 25686, 48017, 46293, 42292, 12500, 33726, 10666, 50826, 60563, 4308, 27664, 4987, 48313, 42479, 1923, 61315, 28442, 11220, 4620, 56833, 17019, 5167, 48029, 30620, 1475, 37974, 6466, 34327, 35557, 14768, 30001, 6776, 8307, 46905, 19750, 8789, 20881, 12467, 45464, 45783, 11271, 58252, 25592, 5489, 59532, 41643, 52024, 57920, 23201, 45426, 56902, 3313, 3757, 42857, 33408, 31987, 26116, 36160, 4975, 31376, 38806, 19430, 63308, 60396, 45968, 43692, 47447, 35702, 17156, 21236, 38429, 52073, 6813, 42037, 40244, 53676, 39370, 483, 22690, 24885, 65302, 28352, 46744, 22849, 59796, 63371, 34126, 35260, 22533, 59843, 59639, 18663, 27499, 58972, 7654, 5427, 50463, 43316, 36032, 54421, 32873, 8235, 1474, 1622, 33945, 63066, 19179, 18627, 29607, 24119, 28231, 26629, 7015, 41218, 56768, 590, 3679, 16123, 63536, 26628, 54486, 20153, 21632, 16518, 23815, 18532, 1234, 55884, 57717, 45417, 5727, 46106, 55877, 1667, 34709, 12451, 42893, 36725, 61126, 62241, 13398, 45757, 52243, 50597, 62071, 704, 52920, 52889, 6863, 37406, 1692, 54961, 25944, 22730, 59173, 17151, 33552, 38092, 14686, 63326, 21481, 45489, 16667, 45185, 1329, 44800, 48261, 52069, 13092, 43297, 58747, 55409, 57613, 25367, 62382, 38314, 17117, 11390, 49008, 60592, 11655, 56242, 14649, 23123, 5413, 33018, 13169, 24529, 41456, 43839, 58859, 62391, 64524, 9527, 22712, 26799, 11826, 37115, 25626, 42117, 27211, 10584, 35780, 49466, 1250, 61522, 49377, 16968, 38560, 21340, 64509, 57255, 36300, 6492, 60747, 38580, 61373, 21298, 22566, 13120, 63517, 57754, 44406, 55520, 29089, 1858, 4974, 32511, 47776, 1905, 30089, 61179, 11162, 37811, 46231, 45921, 28212, 33441, 37640, 12836, 49904, 14491, 50239, 2385, 36380, 62202, 46637, 47296, 41839, 25051, 45329, 28695, 53255, 23041, 9926, 34495, 540, 30106, 60695, 21831, 57834, 47391, 57986, 8695, 11506, 5905, 49325, 18163, 4200, 37110, 1255, 44590, 50146, 62295, 23860, 48293, 856, 12294, 24124, 32856, 36554, 42091, 23422, 58760, 50723, 17432, 43332, 8657, 37808, 39925, 33863, 732, 17282, 50850, 36652, 62847, 30045, 40870, 46122, 6697, 17887, 15027, 64551, 27355, 40213, 36658, 14632, 49371, 8658, 15202, 32433, 48155, 64806, 52649, 35981, 31494, 7890, 60888, 1730, 62342, 35678, 52310, 33231, 34230, 25503, 26893, 24186, 16700, 62083, 59597, 55952, 45488, 14933, 3442, 45508, 61583, 27162, 19033, 24893, 5086, 58883, 8417, 46783, 59438, 3870, 33482, 26940, 9105, 57710, 34212, 34482, 23471, 57107, 61504, 7217, 49361, 50461, 55600, 40792, 41736, 4257, 21200, 2459, 57266, 3332, 19605, 51511, 28460, 39360, 63606, 33140, 65189, 20035, 47348, 55837, 15971, 20417, 37433, 36583, 29516, 50638, 22384, 5226, 12542, 14615, 32943, 40247, 58214, 58016, 20321, 32311, 64862, 4206, 11836, 7613, 2738, 63958, 60494, 6215, 19086, 41304, 5604, 4662, 42779, 23062, 299, 21983, 54524, 10120, 41230, 25713, 39447, 11902, 43539, 22656, 41870, 32149, 85, 62554, 60610, 23782, 56287, 10484, 17065, 34767, 14044, 10381, 64066, 48730, 5936, 38894, 24731, 34609, 8042, 26766, 61990, 7079, 50719, 26598, 12780, 29579, 6973, 60162, 40897, 57312, 24238, 52484, 25994, 14553, 35478, 34832, 25895, 32629, 22828, 3439, 32731, 15474, 35122, 20014, 2377, 47305, 62512, 41701, 50793, 52711, 41971, 45389, 4879, 923, 28924, 55425, 27539, 62478, 37259, 9295, 12175, 22236, 34841, 19373, 12305, 65430, 18597, 56515, 56581, 39311, 9300, 61915, 9239, 59325, 40931, 62768, 2821, 20751, 33420, 15803, 21618, 65483, 43955, 59916, 17992, 11883, 15933, 33350, 1976, 9866, 1593, 57555, 22781, 5300, 60234, 5815, 9086, 31159, 45881, 64210, 3474, 30178, 16499, 26491, 33082, 21524, 32211, 33809, 58982, 52677, 1055, 22372, 53634, 11373, 11673, 41667, 17719, 8427, 62726, 59463, 1963, 3698, 53932, 47745, 11479, 46044, 62256, 29568, 63364, 53314, 32359, 51955, 61847, 12597, 23870, 54792, 18161, 30802, 53250, 34900, 46856, 5775, 48698, 48789, 45587, 60046, 47456, 37717, 17373, 39067, 21436, 15470, 29834, 6469, 18734, 27683, 52402, 16220, 39137, 15405, 5149, 26055, 52573, 20375, 47432, 64091, 29748, 22167, 14028, 22149, 21885, 37423, 21761, 55902, 41229, 20932, 839, 52551, 38419, 31744, 7163, 58733, 40786, 14845, 20921, 49680, 24329, 3732, 26225, 30058, 15618, 52850, 47535, 21369, 42968, 23667, 36627, 43349, 31484, 8545, 37594, 24141, 40781, 27791, 64171, 15590, 14437, 56463, 9894, 23168, 58154, 61759, 35545, 45822, 39694, 44643, 48308, 4969, 32168, 42273, 4462, 10807, 27739, 36771, 24482, 18248, 44300, 29704, 12516, 2911, 45375, 34666, 13768, 45183, 30005, 43425, 61203, 58293, 42423, 49186, 60790, 53462, 21505, 21851, 43748, 36480, 62967, 58895, 9875, 53673, 35851, 50299, 48575, 64120, 12526, 3108, 21450, 27200, 20491, 15050, 64678, 19162, 28571, 30750, 46559, 54656, 56472, 20297, 32730, 43147, 31527, 32187, 35378, 27449, 59694, 63662, 14665, 9429, 9515, 15246, 6821, 6721, 22505, 18699, 52036, 26496, 17031, 25234, 5350, 32960, 38028, 7473, 38904, 51239, 7743, 7092, 6526, 1752, 27192, 6956, 26, 45676, 19526, 17726, 7281, 22832, 18277, 33574, 12711, 62519, 33437, 4301, 10099, 28314, 23122, 54585, 62826, 389, 9036, 2741, 39265, 58134, 16027, 40630, 10441, 39393, 51348, 34885, 61661, 55653, 27894, 40017, 48751, 58858, 31612, 59143, 44015, 33644, 40163, 13357, 62970, 37576, 9099, 52848, 6117, 14056, 42641, 42842, 48587, 24258, 53239, 47803, 45937, 2465, 30941, 12234, 44624, 4361, 23174, 33379, 39147, 34270, 51127, 64212, 45993, 14669, 13895, 9050, 35457, 11858, 31447, 6823, 49151, 39614, 29052, 506, 13126, 56592, 7909, 38286, 48300, 61400, 36962, 47440, 56713, 50176, 11927, 56952, 52671, 64761, 20539, 40262, 28949, 7695, 35408, 45628, 37450, 39435, 20519, 28649, 61258, 30184, 59113, 41866, 39732, 35647, 60603, 7527, 55325, 54388, 39500, 55065, 44482, 17150, 9691, 9969, 46714, 2525, 45807, 13035, 44548, 50718, 10770, 58633, 56780, 20854, 61985, 12031, 27811, 52202, 61401, 2746, 7359, 37764, 52450, 48979, 45402, 63719, 64962, 27606, 26772, 45028, 45808, 2768, 7153, 42879, 64752, 55868, 31581, 60437, 36600, 53822, 27678, 58748, 63132, 46010, 30456, 33959, 7535, 7908, 33069, 29327, 58963, 5362, 10828, 35280, 18272, 63643, 32890, 54731, 60116, 44745, 23008, 61306, 21596, 19609, 54143, 18934, 39591, 1848, 23154, 3263, 27902, 64530, 64131, 32130, 58155, 13442, 7265, 57441, 35528, 36379, 50464, 20712, 48388, 1769, 45853, 6693, 59373, 36632, 32393, 45520, 2637, 11470, 1596, 19782, 50979, 954, 59141, 56238, 2753, 61636, 31094, 50123, 19488, 24111, 53878, 2220, 39889, 55419, 16044, 62656, 15428, 7311, 19010, 48064, 57804, 62764, 38474, 30072, 21497, 6833, 56458, 21717, 45717, 14036, 36269, 28650, 46526, 30272, 26112, 23737, 60421, 54451, 31738, 43444, 21919, 64207, 55439, 34556, 40088, 38906, 52098, 61292, 32786, 1448, 208, 61454, 7731, 42922, 43602, 52045, 19234, 35471, 4705, 3290, 32505, 44895, 60520, 10622, 57116, 49913, 22984, 2302, 11732, 61631, 20107, 5516, 14433, 53419, 38393, 23745, 17259, 36603, 23773, 32160, 52815, 52571, 19362, 18733, 30120, 9281, 17617, 12270, 42982, 16104, 32972, 53803, 21927, 40056, 46534, 25056, 33680, 16748, 13687, 2851, 25250, 54151, 63812, 29434, 19828, 58221, 57528, 49376, 2246, 19935, 26662, 42087, 41585, 64312, 25523, 56564, 47458, 30189, 38857, 17766, 5995, 54850, 54084, 57724, 26887, 47473, 28437, 25153, 47611, 27494, 41740, 6364, 64188, 32961, 22043, 51951, 30550, 14518, 32062, 52864, 32594, 36162, 53566, 52111, 59171, 19563, 30688, 38990, 35289, 44321, 34360, 33524, 47950, 48983, 32870, 27861, 22412, 5222, 17565, 50856, 55219, 60826, 63881, 33648, 36079, 31544, 49308, 9976, 63959, 59761, 47943, 21856, 30839, 33135, 24449, 14562, 41415, 30902, 27776, 29457, 4197, 34448, 57568, 40808, 44288, 17502, 61027, 21266, 611, 21534, 4508, 29234, 34013, 15794, 13238, 51831, 45315, 19690, 30629, 41629, 16192, 49029, 22943, 15751, 20878, 30090, 233, 31365, 60002, 16571, 30893, 54983, 40660, 15667, 37534, 38828, 29716, 45900, 13010, 22017, 39782, 16384, 8294, 56407, 56258, 3273, 17444, 5635, 52943, 48593, 45528, 37978, 28861, 37920, 46624, 11335, 19611, 62988, 43284, 42022, 40997, 9321, 2809, 64002, 2480, 9055, 59585, 35827, 47892, 43973, 15516, 32064, 63800, 55015, 47250, 42654, 57157, 9593, 18251, 63616, 62058, 27041, 29489, 21274, 53085, 54095, 56749, 40494, 7737, 16232, 7005, 4176, 26746, 24435, 1062, 10616, 8063, 58553, 11199, 13075, 4573, 34626, 42360, 64257, 47501, 39110, 46713, 40251, 61606, 34796, 23430, 6051, 34346, 31467, 30884, 62644, 63007, 19076, 18453, 36827, 52424, 1472, 47125, 42694, 38258, 38060, 28060, 60147, 9984, 51404, 17053, 54960, 24727, 21390, 60156, 63516, 4380, 18487, 43707, 30630, 35268, 47645, 35654, 25456, 54630, 62162, 16894, 11856, 13982, 53915, 21323, 45008, 46383, 23749, 46634, 49333, 2245, 3197, 5466, 60558, 49135, 54818, 41530]}	10217	\\x00000000000000000000000000000000
\.


--
-- Data for Name: device_profile; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile (id, tenant_id, created_at, updated_at, name, region, mac_version, reg_params_revision, adr_algorithm_id, payload_codec_runtime, uplink_interval, device_status_req_interval, supports_otaa, supports_class_b, supports_class_c, tags, payload_codec_script, flush_queue_on_activate, description, measurements, auto_detect_measurements, region_config_id, allow_roaming, rx1_delay, abp_params, class_b_params, class_c_params, relay_params, app_layer_params, device_id, firmware_version, vendor_profile_id, supported_uplink_data_rates) FROM stdin;
60971949-e5e0-47c0-a527-8e4544ece0f8	2aa43e59-68f9-4d56-b2c3-937cf0dd4525	2026-06-12 21:29:12.229532+08	2026-06-12 21:29:12.229532+08	test_camera	AU915	1.0.2	B	default	NONE	3600	1	t	f	f	{}	/**\n * Decode uplink function\n * \n * @param {object} input\n * @param {number[]} input.bytes Byte array containing the uplink payload, e.g. [255, 230, 255, 0]\n * @param {number} input.fPort Uplink fPort.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{data: object, errors: string[], warnings: string[]}}\n * An object containing:\n * - data: Object representing the decoded payload.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction decodeUplink(input) {\n  return {\n    data: {\n      temp: 22.5,\n    }\n  };\n}\n\n/**\n * Encode downlink function.\n * \n * @param {object} input\n * @param {object} input.data Object representing the payload that must be encoded.\n * @param {Record<string, string>} input.variables Object containing the configured device variables.\n * \n * @returns {{bytes: number[], fPort: number, errors: string[], warnings: string[]}}\n * An object containing:\n * - bytes: Byte array containing the downlink payload.\n * - fPort: The downlink LoRaWAN fPort.\n * - errors: An array of errors (optional).\n * - warnings: An array of warnings (optional).\n */\nfunction encodeDownlink(input) {\n  return {\n    fPort: 10,\n    bytes: [225, 230, 255, 0],\n  };\n}\n	t		{}	t	\N	f	0	\N	\N	\N	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
c416bab4-fbae-4281-b695-26a3daa748f6	77ec53ab-0069-4739-8935-3391005ce8b5	2026-07-10 21:04:32.816956+08	2026-07-11 20:43:36.971576+08	insect-node-profile	AU915	1.0.2	A	default	JS	1200	1	t	f	f	{}	function decodeUplink(input) {\n  var b = input.bytes;\n  if (b.length < 5) { return { data: {}, errors: ["expected 5 bytes"] }; }\n  var insect_count = (b[0] * 256) + b[1];\n  var max_conf = b[2] / 100.0;\n  var lux = (b[3] * 256) + b[4];\n  return { data: { insect_count: insect_count, max_conf: max_conf, lux: lux } };\n}\nfunction encodeDownlink(input) { return { bytes: [] }; }	t	t	{"lux": {"kind": "UNKNOWN", "name": ""}, "max_conf": {"kind": "UNKNOWN", "name": ""}, "insect_count": {"kind": "UNKNOWN", "name": ""}}	t	\N	f	0	\N	\N	\N	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
a7e919f6-805b-4738-9ee5-6a8f916fde83	77ec53ab-0069-4739-8935-3391005ce8b5	2026-06-02 19:40:06.971033+08	2026-09-07 11:54:14.105012+08	Enviromental Node	AU915	1.0.2	A	default	JS	3600	1	t	f	f	{}	function decodeUplink(input) {\n  var b = input.bytes;\n  if (b.length < 15) {\n    return { data: {}, errors: ["expected 15 bytes, got " + b.length] };\n  }\n  var tRaw = (b[0] * 256) + b[1];\n  if (tRaw > 32767) {\n    tRaw = tRaw - 65536;\n  }\n  var temperature = tRaw / 100.0;\n  var humidity = ((b[2] * 256) + b[3]) / 100.0;\n  var soil_moisture = b[4];\n  var latRaw = (b[5] * 16777216) + (b[6] * 65536) + (b[7] * 256) + b[8];\n  if (latRaw > 2147483647) {\n    latRaw = latRaw - 4294967296;\n  }\n  var latitude = latRaw / 1000000.0;\n  var lonRaw = (b[9] * 16777216) + (b[10] * 65536) + (b[11] * 256) + b[12];\n  if (lonRaw > 2147483647) {\n    lonRaw = lonRaw - 4294967296;\n  }\n  var longitude = lonRaw / 1000000.0;\n  var distance = (b[13] * 256) + b[14];   // A02YYUW ultrasonic, mm\n  return {\n    data: {\n      temperature: temperature,\n      humidity: humidity,\n      soil_moisture: soil_moisture,\n      latitude: latitude,\n      longitude: longitude,\n      distance: distance\n    }\n  };\n}\nfunction encodeDownlink(input) {\n  return { bytes: [] };\n}	t		{"distance": {"kind": "UNKNOWN", "name": ""}, "humidity": {"kind": "UNKNOWN", "name": ""}, "latitude": {"kind": "UNKNOWN", "name": ""}, "longitude": {"kind": "UNKNOWN", "name": ""}, "temperature": {"kind": "UNKNOWN", "name": ""}, "soil_moisture": {"kind": "UNKNOWN", "name": ""}}	t	au915_1	f	0	\N	\N	\N	\N	{"ts003_f_port": 202, "ts004_f_port": 201, "ts005_f_port": 200, "ts003_version": null, "ts004_version": null, "ts005_version": null}	\N		0	{}
\.


--
-- Data for Name: device_profile_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_device (id, vendor_id, created_at, updated_at, name, description, metadata) FROM stdin;
\.


--
-- Data for Name: device_profile_template; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_template (id, created_at, updated_at, name, description, vendor, firmware, region, mac_version, reg_params_revision, adr_algorithm_id, payload_codec_runtime, payload_codec_script, uplink_interval, device_status_req_interval, flush_queue_on_activate, supports_otaa, supports_class_b, supports_class_c, class_b_timeout, class_b_ping_slot_periodicity, class_b_ping_slot_dr, class_b_ping_slot_freq, class_c_timeout, abp_rx1_delay, abp_rx1_dr_offset, abp_rx2_dr, abp_rx2_freq, tags, measurements, auto_detect_measurements) FROM stdin;
\.


--
-- Data for Name: device_profile_vendor; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_profile_vendor (id, created_at, updated_at, name, vendor_id, ouis, metadata) FROM stdin;
\.


--
-- Data for Name: device_queue_item; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.device_queue_item (id, dev_eui, created_at, f_port, confirmed, data, is_pending, f_cnt_down, timeout_after, is_encrypted, expires_at) FROM stdin;
\.


--
-- Data for Name: fuota_deployment; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment (id, created_at, updated_at, started_at, completed_at, name, application_id, device_profile_id, multicast_addr, multicast_key, multicast_group_type, multicast_class_c_scheduling_type, multicast_dr, multicast_class_b_ping_slot_periodicity, multicast_frequency, multicast_timeout, multicast_session_start, multicast_session_end, unicast_max_retry_count, fragmentation_fragment_size, fragmentation_redundancy_percentage, fragmentation_session_index, fragmentation_matrix, fragmentation_block_ack_delay, fragmentation_descriptor, request_fragmentation_session_status, payload, on_complete_set_device_tags) FROM stdin;
\.


--
-- Data for Name: fuota_deployment_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_device (fuota_deployment_id, dev_eui, created_at, completed_at, mc_group_setup_completed_at, mc_session_completed_at, frag_session_setup_completed_at, frag_status_completed_at, error_msg) FROM stdin;
\.


--
-- Data for Name: fuota_deployment_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_gateway (fuota_deployment_id, gateway_id, created_at) FROM stdin;
\.


--
-- Data for Name: fuota_deployment_job; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.fuota_deployment_job (fuota_deployment_id, job, created_at, completed_at, max_retry_count, attempt_count, scheduler_run_after, warning_msg, error_msg) FROM stdin;
\.


--
-- Data for Name: gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.gateway (gateway_id, tenant_id, created_at, updated_at, last_seen_at, name, description, latitude, longitude, altitude, stats_interval_secs, tls_certificate, tags, properties) FROM stdin;
\\x00016c001f16188e	77ec53ab-0069-4739-8935-3391005ce8b5	2026-06-02 09:56:35.917692+08	2026-06-02 09:56:35.917692+08	2026-10-01 22:38:24.797251+08	ben		0	0	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\\x927b2d2b837ce5a2	2aa43e59-68f9-4d56-b2c3-937cf0dd4525	2026-06-12 21:32:07.041166+08	2026-06-12 21:32:07.041166+08	2026-08-24 23:26:46.780939+08	bobby		0	0	0	30	\N	{}	{"region_config_id": "au915_1", "region_common_name": "AU915"}
\.


--
-- Data for Name: multicast_group; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group (id, application_id, created_at, updated_at, name, region, mc_addr, mc_nwk_s_key, mc_app_s_key, f_cnt, group_type, dr, frequency, class_b_ping_slot_periodicity, class_c_scheduling_type) FROM stdin;
\.


--
-- Data for Name: multicast_group_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_device (multicast_group_id, dev_eui, created_at) FROM stdin;
\.


--
-- Data for Name: multicast_group_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_gateway (multicast_group_id, gateway_id, created_at) FROM stdin;
\.


--
-- Data for Name: multicast_group_queue_item; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.multicast_group_queue_item (id, created_at, scheduler_run_after, multicast_group_id, gateway_id, f_cnt, f_port, data, emit_at_time_since_gps_epoch, expires_at) FROM stdin;
\.


--
-- Data for Name: relay_device; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.relay_device (relay_dev_eui, dev_eui, created_at) FROM stdin;
\.


--
-- Data for Name: relay_gateway; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.relay_gateway (tenant_id, relay_id, created_at, updated_at, last_seen_at, name, description, stats_interval_secs, region_config_id) FROM stdin;
\.


--
-- Data for Name: tenant; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.tenant (id, created_at, updated_at, name, description, can_have_gateways, max_device_count, max_gateway_count, private_gateways_up, private_gateways_down, tags) FROM stdin;
77ec53ab-0069-4739-8935-3391005ce8b5	2026-06-02 09:11:42.336049+08	2026-06-02 09:11:42.336049+08	ChirpStack		t	0	0	f	f	{}
2aa43e59-68f9-4d56-b2c3-937cf0dd4525	2026-06-12 21:27:06.679397+08	2026-06-12 21:27:06.679397+08	Camera_Node		t	0	0	f	f	{}
\.


--
-- Data for Name: tenant_user; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public.tenant_user (tenant_id, user_id, created_at, updated_at, is_admin, is_device_admin, is_gateway_admin) FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: chirpstack
--

COPY public."user" (id, external_id, created_at, updated_at, is_admin, is_active, email, email_verified, password_hash, note) FROM stdin;
0353c63e-b774-4b07-a194-25ade1ebc408	\N	2026-06-02 09:11:42.336049+08	2026-06-02 09:11:42.336049+08	t	t	admin	f	REDACTED	
\.


--
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: api_key api_key_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_pkey PRIMARY KEY (id);


--
-- Name: application_integration application_integration_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application_integration
    ADD CONSTRAINT application_integration_pkey PRIMARY KEY (application_id, kind);


--
-- Name: application application_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id);


--
-- Name: device_keys device_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_pkey PRIMARY KEY (dev_eui);


--
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (dev_eui);


--
-- Name: device_profile_device device_profile_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_device
    ADD CONSTRAINT device_profile_device_pkey PRIMARY KEY (id);


--
-- Name: device_profile device_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_pkey PRIMARY KEY (id);


--
-- Name: device_profile_template device_profile_template_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_template
    ADD CONSTRAINT device_profile_template_pkey PRIMARY KEY (id);


--
-- Name: device_profile_vendor device_profile_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_vendor
    ADD CONSTRAINT device_profile_vendor_pkey PRIMARY KEY (id);


--
-- Name: device_queue_item device_queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_queue_item
    ADD CONSTRAINT device_queue_item_pkey PRIMARY KEY (id);


--
-- Name: fuota_deployment_device fuota_deployment_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_pkey PRIMARY KEY (fuota_deployment_id, dev_eui);


--
-- Name: fuota_deployment_gateway fuota_deployment_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_pkey PRIMARY KEY (fuota_deployment_id, gateway_id);


--
-- Name: fuota_deployment_job fuota_deployment_job_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_job
    ADD CONSTRAINT fuota_deployment_job_pkey PRIMARY KEY (fuota_deployment_id, job);


--
-- Name: fuota_deployment fuota_deployment_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_pkey PRIMARY KEY (id);


--
-- Name: gateway gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_pkey PRIMARY KEY (gateway_id);


--
-- Name: multicast_group_device multicast_group_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_pkey PRIMARY KEY (multicast_group_id, dev_eui);


--
-- Name: multicast_group_gateway multicast_group_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_pkey PRIMARY KEY (multicast_group_id, gateway_id);


--
-- Name: multicast_group multicast_group_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_pkey PRIMARY KEY (id);


--
-- Name: multicast_group_queue_item multicast_group_queue_item_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_pkey PRIMARY KEY (id);


--
-- Name: relay_device relay_device_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_pkey PRIMARY KEY (relay_dev_eui, dev_eui);


--
-- Name: relay_gateway relay_gateway_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_gateway
    ADD CONSTRAINT relay_gateway_pkey PRIMARY KEY (tenant_id, relay_id);


--
-- Name: tenant tenant_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant
    ADD CONSTRAINT tenant_pkey PRIMARY KEY (id);


--
-- Name: tenant_user tenant_user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_pkey PRIMARY KEY (tenant_id, user_id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: idx_api_key_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_api_key_tenant_id ON public.api_key USING btree (tenant_id);


--
-- Name: idx_application_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_name_trgm ON public.application USING gin (name public.gin_trgm_ops);


--
-- Name: idx_application_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_tags ON public.application USING gin (tags);


--
-- Name: idx_application_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_application_tenant_id ON public.application USING btree (tenant_id);


--
-- Name: idx_device_application_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_application_id ON public.device USING btree (application_id);


--
-- Name: idx_device_dev_addr; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_addr ON public.device USING btree (dev_addr);


--
-- Name: idx_device_dev_addr_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_addr_trgm ON public.device USING gin (encode(dev_addr, 'hex'::text) public.gin_trgm_ops);


--
-- Name: idx_device_dev_eui_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_dev_eui_trgm ON public.device USING gin (encode(dev_eui, 'hex'::text) public.gin_trgm_ops);


--
-- Name: idx_device_device_profile_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_device_profile_id ON public.device USING btree (device_profile_id);


--
-- Name: idx_device_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_name_trgm ON public.device USING gin (name public.gin_trgm_ops);


--
-- Name: idx_device_profile_device_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_device_id ON public.device_profile USING btree (device_id);


--
-- Name: idx_device_profile_device_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_device_name_trgm ON public.device_profile_device USING gin (name public.gin_trgm_ops);


--
-- Name: idx_device_profile_device_vendor_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_device_vendor_id ON public.device_profile_device USING btree (vendor_id);


--
-- Name: idx_device_profile_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_name_trgm ON public.device_profile USING gin (name public.gin_trgm_ops);


--
-- Name: idx_device_profile_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_tags ON public.device_profile USING gin (tags);


--
-- Name: idx_device_profile_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_tenant_id ON public.device_profile USING btree (tenant_id);


--
-- Name: idx_device_profile_vendor_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_vendor_name_trgm ON public.device_profile_vendor USING gin (name public.gin_trgm_ops);


--
-- Name: idx_device_profile_vendor_ouis; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_vendor_ouis ON public.device_profile_vendor USING btree (ouis);


--
-- Name: idx_device_profile_vendor_vendor_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_profile_vendor_vendor_id ON public.device_profile_vendor USING btree (vendor_id);


--
-- Name: idx_device_queue_item_created_at; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_created_at ON public.device_queue_item USING btree (created_at);


--
-- Name: idx_device_queue_item_dev_eui; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_dev_eui ON public.device_queue_item USING btree (dev_eui);


--
-- Name: idx_device_queue_item_timeout_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_queue_item_timeout_after ON public.device_queue_item USING btree (timeout_after);


--
-- Name: idx_device_secondary_dev_addr; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_secondary_dev_addr ON public.device USING btree (secondary_dev_addr);


--
-- Name: idx_device_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_device_tags ON public.device USING gin (tags);


--
-- Name: idx_fuota_deployment_job_completed_at; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_fuota_deployment_job_completed_at ON public.fuota_deployment_job USING btree (completed_at);


--
-- Name: idx_fuota_deployment_job_scheduler_run_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_fuota_deployment_job_scheduler_run_after ON public.fuota_deployment_job USING btree (scheduler_run_after);


--
-- Name: idx_gateway_id_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_id_trgm ON public.gateway USING gin (encode(gateway_id, 'hex'::text) public.gin_trgm_ops);


--
-- Name: idx_gateway_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_name_trgm ON public.gateway USING gin (name public.gin_trgm_ops);


--
-- Name: idx_gateway_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_tags ON public.gateway USING gin (tags);


--
-- Name: idx_gateway_tenant_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_gateway_tenant_id ON public.gateway USING btree (tenant_id);


--
-- Name: idx_multicast_group_application_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_application_id ON public.multicast_group USING btree (application_id);


--
-- Name: idx_multicast_group_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_name_trgm ON public.multicast_group USING gin (name public.gin_trgm_ops);


--
-- Name: idx_multicast_group_queue_item_multicast_group_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_queue_item_multicast_group_id ON public.multicast_group_queue_item USING btree (multicast_group_id);


--
-- Name: idx_multicast_group_queue_item_scheduler_run_after; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_multicast_group_queue_item_scheduler_run_after ON public.multicast_group_queue_item USING btree (scheduler_run_after);


--
-- Name: idx_tenant_name_trgm; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_name_trgm ON public.tenant USING gin (name public.gin_trgm_ops);


--
-- Name: idx_tenant_tags; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_tags ON public.tenant USING gin (tags);


--
-- Name: idx_tenant_user_user_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE INDEX idx_tenant_user_user_id ON public.tenant_user USING btree (user_id);


--
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE UNIQUE INDEX idx_user_email ON public."user" USING btree (email);


--
-- Name: idx_user_external_id; Type: INDEX; Schema: public; Owner: chirpstack
--

CREATE UNIQUE INDEX idx_user_external_id ON public."user" USING btree (external_id);


--
-- Name: api_key api_key_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.api_key
    ADD CONSTRAINT api_key_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- Name: application_integration application_integration_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application_integration
    ADD CONSTRAINT application_integration_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- Name: application application_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- Name: device device_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- Name: device device_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(id) ON DELETE CASCADE;


--
-- Name: device_keys device_keys_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_keys
    ADD CONSTRAINT device_keys_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- Name: device_profile device_profile_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device_profile_device(id) ON DELETE CASCADE;


--
-- Name: device_profile_device device_profile_device_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile_device
    ADD CONSTRAINT device_profile_device_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.device_profile_vendor(id) ON DELETE CASCADE;


--
-- Name: device_profile device_profile_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_profile
    ADD CONSTRAINT device_profile_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- Name: device_queue_item device_queue_item_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.device_queue_item
    ADD CONSTRAINT device_queue_item_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- Name: fuota_deployment fuota_deployment_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- Name: fuota_deployment_device fuota_deployment_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- Name: fuota_deployment_device fuota_deployment_device_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_device
    ADD CONSTRAINT fuota_deployment_device_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- Name: fuota_deployment fuota_deployment_device_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment
    ADD CONSTRAINT fuota_deployment_device_profile_id_fkey FOREIGN KEY (device_profile_id) REFERENCES public.device_profile(id) ON DELETE CASCADE;


--
-- Name: fuota_deployment_gateway fuota_deployment_gateway_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- Name: fuota_deployment_gateway fuota_deployment_gateway_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_gateway
    ADD CONSTRAINT fuota_deployment_gateway_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- Name: fuota_deployment_job fuota_deployment_job_fuota_deployment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.fuota_deployment_job
    ADD CONSTRAINT fuota_deployment_job_fuota_deployment_id_fkey FOREIGN KEY (fuota_deployment_id) REFERENCES public.fuota_deployment(id) ON DELETE CASCADE;


--
-- Name: gateway gateway_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.gateway
    ADD CONSTRAINT gateway_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- Name: multicast_group multicast_group_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group
    ADD CONSTRAINT multicast_group_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.application(id) ON DELETE CASCADE;


--
-- Name: multicast_group_device multicast_group_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- Name: multicast_group_device multicast_group_device_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_device
    ADD CONSTRAINT multicast_group_device_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- Name: multicast_group_gateway multicast_group_gateway_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- Name: multicast_group_gateway multicast_group_gateway_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_gateway
    ADD CONSTRAINT multicast_group_gateway_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- Name: multicast_group_queue_item multicast_group_queue_item_gateway_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES public.gateway(gateway_id) ON DELETE CASCADE;


--
-- Name: multicast_group_queue_item multicast_group_queue_item_multicast_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.multicast_group_queue_item
    ADD CONSTRAINT multicast_group_queue_item_multicast_group_id_fkey FOREIGN KEY (multicast_group_id) REFERENCES public.multicast_group(id) ON DELETE CASCADE;


--
-- Name: relay_device relay_device_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_dev_eui_fkey FOREIGN KEY (dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- Name: relay_device relay_device_relay_dev_eui_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_device
    ADD CONSTRAINT relay_device_relay_dev_eui_fkey FOREIGN KEY (relay_dev_eui) REFERENCES public.device(dev_eui) ON DELETE CASCADE;


--
-- Name: relay_gateway relay_gateway_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.relay_gateway
    ADD CONSTRAINT relay_gateway_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- Name: tenant_user tenant_user_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant(id) ON DELETE CASCADE;


--
-- Name: tenant_user tenant_user_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: chirpstack
--

ALTER TABLE ONLY public.tenant_user
    ADD CONSTRAINT tenant_user_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict zLwlg6CQuCz5edpt6ZMfQTdTNRoLGA9xf4IuSUn5EsZe71vsF9Br8yZiztlI2Dm

