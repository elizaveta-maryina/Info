--Part4
-- Создание базы данных---------------------------------------------------------------------------------
CREATE DATABASE info_21_part_4;

--Создание таблиц---------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tableName_1 (
    id BIGSERIAL PRIMARY KEY,
    name varchar NOT NULL
);

CREATE TABLE IF NOT EXISTS TableName_2 (
    id BIGSERIAL PRIMARY KEY,
    name varchar NOT NULL
);

CREATE TABLE IF NOT EXISTS _TableName_ (
    id BIGSERIAL PRIMARY KEY,
    name varchar NOT NULL
);

CREATE TABLE IF NOT EXISTS Table_name (
    id BIGSERIAL PRIMARY KEY,
    name varchar NOT NULL
);

CREATE TABLE IF NOT EXISTS Table_1 (
    id BIGSERIAL PRIMARY KEY,
    name varchar NOT NULL
);

--Создание функций---------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_test_1()
    RETURNS integer
AS $$
DECLARE
        i int;
BEGIN
    SELECT count(*) INTO i FROM Table_1;
    RETURN i;
END;
$$ language plpgsql;

SELECT * FROM fn_test_1();

---------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_test_2(k int)
    RETURNS integer
AS $$
DECLARE
        i int;
BEGIN
    SELECT k INTO i;
    RETURN i;
END;
$$ language plpgsql;

SELECT * FROM fn_test_2(2);

CREATE OR REPLACE FUNCTION fn_test_3(k int)
    RETURNS integer
AS $$
DECLARE
        i int;
BEGIN
    SELECT k INTO i;
    RETURN i;
END;
$$ language plpgsql;

SELECT * FROM fn_test_3(2);

--Создание триггеров---------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_trigger_1()
    RETURNS TRIGGER
AS
$$
BEGIN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_name_1  AFTER INSERT ON Table_1
FOR EACH ROW EXECUTE FUNCTION fn_trigger_1();

---------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_trigger_2()
    RETURNS TRIGGER
AS
$$
BEGIN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_name_2  BEFORE INSERT ON Table_1
FOR EACH ROW EXECUTE FUNCTION fn_trigger_2();

-- ===========================================================================================================================
-- 1) Создать хранимую процедуру, которая, не уничтожая базу данных, уничтожает все те таблицы текущей базы данных,
-- имена которых начинаются с фразы 'TableName'.

CREATE OR REPLACE PROCEDURE pr_drop_table_TableName_() AS
$$
DECLARE
    i record;
BEGIN
    FOR i IN (SELECT tablename FROM pg_catalog.pg_tables
        WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'
        AND tablename ~* '^TableName') -- ~* - проверяет соответствие регулярному выражению, ^ - соответствует началу строки
    LOOP
        EXECUTE 'drop table if exists ' || quote_ident(i.tablename) || ' cascade';
        --Для надёжности, выражения, содержащие идентификаторы столбцов и таблиц должны использовать
        -- функцию quote_ident при добавлении в текст запроса
    END LOOP;
END;
$$ language plpgsql;

CALL pr_drop_table_TableName_();

-- ===========================================================================================================================
-- 2) Создать хранимую процедуру с выходным параметром, которая выводит список имен и параметров всех скалярных SQL
-- функций пользователя в текущей базе данных. Имена функций без параметров не выводить. Имена и список параметров
-- должны выводиться в одну строку. Выходной параметр возвращает количество найденных функций.

CREATE OR REPLACE PROCEDURE pr_list_fncs_with_parametr(out fn_count integer, result refcursor default 'result')
AS
$$
BEGIN
    OPEN result FOR
        SELECT routine_name, string_agg(parameters.parameter_name, ',') AS parameters
        FROM information_schema.routines
                 JOIN information_schema.parameters
                      ON routines.specific_name = parameters.specific_name
        WHERE routines.specific_schema = 'public'
          AND routine_type = 'FUNCTION'
          AND parameters.parameter_name IS NOT NULL
        GROUP BY routine_name;

    fn_count := (SELECT count(*) OVER ()
              FROM information_schema.routines
              JOIN information_schema.parameters ON routines.specific_name = parameters.specific_name
              WHERE routines.specific_schema = 'public'
                AND routine_type = 'FUNCTION'
                AND parameters.parameter_name IS NOT NULL
              GROUP BY routine_name
              LIMIT 1);
END;
$$ language plpgsql;

BEGIN;
CALL pr_list_fncs_with_parametr(NULL);
FETCH ALL FROM "result";
END;
-- ===========================================================================================================================
-- 3) Создать хранимую процедуру с выходным параметром, которая уничтожает все SQL DML триггеры в текущей базе данных.
-- Выходной параметр возвращает количество уничтоженных триггеров.

CREATE OR REPLACE PROCEDURE pr_drop_triggers(out count_drop_trg int)
AS $$

    DECLARE name_trigger varchar; table_triggers varchar;
BEGIN
    SELECT DISTINCT count(trigger_name) INTO count_drop_trg
        FROM information_schema.triggers;
        FOR name_trigger, table_triggers IN
            (SELECT DISTINCT trigger_name, event_object_table FROM information_schema.triggers)
        LOOP
            EXECUTE CONCAT('DROP TRIGGER ', name_trigger, ' ON ', table_triggers);
        END LOOP;
END
$$ LANGUAGE plpgsql;

CALL pr_drop_triggers(null);

-- CREATE TRIGGER trg_name_1  AFTER INSERT ON Table_1
-- FOR EACH ROW EXECUTE FUNCTION fn_trigger_1();

-- ===========================================================================================================================
-- 4) Создать хранимую процедуру с входным параметром, которая выводит имена и описания типа объектов (только хранимых
-- процедур и скалярных функций), в тексте которых на языке SQL встречается строка, задаваемая параметром процедуры.

CREATE OR REPLACE PROCEDURE pr_search_object_name(in name varchar, in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        SELECT routine_name,routine_type
        FROM information_schema.routines
        WHERE routine_definition LIKE concat('%', name, '%');
END;
$$ language plpgsql;

BEGIN;
CALL pr_search_object_name('FROM','result' );
FETCH ALL IN "result";
END;
