--Part2
-- ===========================================================================================================================
-- 1)Написать процедуру добавления P2P проверки
-- Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время.
-- Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю).
-- Добавить запись в таблицу P2P.
-- Если задан статус "начало", в качестве проверки указать только что добавленную запись, иначе указать проверку с незавершенным P2P этапом.

CREATE or replace PROCEDURE pr_add_p2p_check(IN checked character varying, IN checking character varying, IN task_name character varying, IN state check_status, IN p2p_time time without time zone)
AS
$$
DECLARE
    id_check integer := 0;
BEGIN
    IF state = 'start'
    THEN
        id_check = (SELECT max(id) FROM checks) + 1;
        INSERT INTO checks (id, peer, task, date) VALUES (id_check, checked, task_name, (SELECT current_date));
    ELSE
        id_check = (SELECT c.id
                    FROM p2p
                    JOIN checks c ON c.id = p2p.check_id
                    WHERE checking_peer = checking AND peer = checked AND task = task_name
                    ORDER BY c.id DESC
                    LIMIT 1);
    END IF;
    INSERT INTO p2p (check_id, checking_peer, state, time) VALUES (id_check, checking, state, p2p_time);
END;
$$ LANGUAGE plpgsql;


CALL pr_add_p2p_check('Enigma', 'Anti-Mage', 'CPP1_s21_matrix+', 'start', '09:00:00');
CALL pr_add_p2p_check('Enigma', 'Anti-Mage', 'CPP1_s21_matrix+', 'success', '09:20:00');

-- ===========================================================================================================================
-- 2) Написать процедуру добавления проверки Verter'ом
-- Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время.
-- Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего задания с самым поздним (по времени) успешным P2P этапом)

CREATE or replace PROCEDURE pr_add_verter_check(IN nickname character varying, IN task_name character varying, IN verter_state check_status, IN check_time time without time zone)
AS
$$
DECLARE
    id_check integer := (SELECT c.id
                         FROM p2p
                         JOIN checks c ON c.id = p2p.check_id AND p2p.state = 'success'
                         AND c.task = task_name AND c.peer = nickname
                         ORDER BY p2p.time
                         LIMIT 1);
BEGIN
    INSERT INTO verter (check_id, state, time) VALUES (id_check, verter_state, check_time);
END;
$$ LANGUAGE plpgsql;

-- CALL pr_add_verter_check('Enigma','CPP1_s21_matrix+','start','09:21:00');
-- CALL pr_add_verter_check('Enigma', 'CPP1_s21_matrix+', 'success', '09:22:00');

-- ===========================================================================================================================
-- 3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints

CREATE OR REPLACE FUNCTION fn_update_transferred_points() RETURNS TRIGGER AS
$$
begin
	IF (new.state = 'start') THEN
		INSERT INTO transferredpoints VALUES(
			(SELECT coalesce((max(id) + 1), 1) FROM transferredpoints),
			new.checking_peer,
			(SELECT peer FROM Checks WHERE id = new.check_id),
			1);
	END IF;
	RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_table_transferred_points  AFTER INSERT ON p2p
FOR EACH ROW EXECUTE FUNCTION fn_update_transferred_points();

CALL pr_add_p2p_check('Anti-Mage', 'Enigma', 'CPP1_s21_matrix+', 'start', '09:00:00');
SELECT * FROM transferredpoints;

-- ===========================================================================================================================
-- 4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
-- Запись считается корректной, если:
-- Количество XP не превышает максимальное доступное для проверяемой задачи
-- Поле Check ссылается на успешную проверку
-- Если запись не прошла проверку, не добавлять её в таблицу.

CREATE OR REPLACE FUNCTION fn_check_correctness_recording()
    RETURNS TRIGGER AS
$$
DECLARE
    status varchar(20);
    max_xp int;
BEGIN
    SELECT tasks.max_xp INTO max_xp
    FROM checks
    JOIN tasks ON tasks.title_name = checks.task;

    SELECT p2p.state INTO status
    FROM checks
    JOIN p2p ON checks.id = p2p.check_id;

    IF new.xp_amount > max_xp THEN
        RAISE EXCEPTION 'количество xp больше, чем максимальное количество xp для этой задачи';
    ELSEIF status = 'failure' THEN
        RAISE EXCEPTION 'проверка завершилась неудачей';
    ELSE
        RETURN new;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_xp BEFORE INSERT ON xp
FOR EACH ROW EXECUTE FUNCTION fn_check_correctness_recording();

-- INSERT INTO xp (check_id, xp_amount) VALUES (12, 1000); --error
-- INSERT INTO xp (check_id, xp_amount) VALUES (12, 200); --update