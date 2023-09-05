--Part 3
-- ===========================================================================================================================
--1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов.
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.

CREATE OR REPLACE FUNCTION fn_transferred_points()
    RETURNS TABLE(peer_1 varchar, peer_2 varchar, points_amount integer)
AS $$
BEGIN
    RETURN QUERY
        WITH tmp AS (SELECT  tp1.id AS id1, tp2.id AS id2, tp1.checking_peer AS chacking_1,
                             tp2.checking_peer AS chacking_2, tp1.checked_peer AS chacked_1,
                             tp2.checked_peer AS chacked_2, tp1.points_amount as points_amount_1,
                             tp2.points_amount as points_amount_2
        FROM transferredpoints tp1
        LEFT OUTER JOIN transferredpoints tp2 ON tp1.checked_peer = tp2.checking_peer
        AND tp1.checking_peer = tp2.checked_peer)

        SELECT chacking_1, chacked_1, (coalesce(points_amount_1, 0) - coalesce(points_amount_2, 0))
        FROM tmp WHERE id1 < id2 OR id2 IS NULL;
END; $$ language plpgsql;

SELECT * FROM fn_transferred_points();

-- ===========================================================================================================================
--2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
-- В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks).
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.

CREATE OR REPLACE FUNCTION fn_successful_checks()
    RETURNS TABLE(peer varchar, task varchar, xp integer) AS
$$
BEGIN
    RETURN QUERY
    SELECT DISTINCT p2p.checking_peer, c.task, xp.xp_amount
    FROM p2p
	JOIN checks c on c.id = p2p.check_id
    JOIN xp on p2p.check_id = xp.check_id
    ORDER BY 1,2,3;
END;
$$ language plpgsql;

SELECT * FROM fn_successful_checks();
-- ===========================================================================================================================
--3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например 12.05.2022.
-- Функция возвращает только список пиров.

CREATE OR REPLACE FUNCTION fn_peers_in_campus(chacking_date date)
    returns TABLE(peers varchar)
as
$$
BEGIN
    RETURN QUERY
    SELECT peer FROM (SELECT peer, count(*) AS count
                      FROM timetracking
                      WHERE date = chacking_date AND state = 2
                      GROUP BY peer) tmp
    WHERE count = 1;
END;
$$ language plpgsql;

SELECT * FROM fn_peers_in_campus('2022-09-21');

-- ===========================================================================================================================
--4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
-- Результат вывести отсортированным по изменению числа поинтов.
-- Формат вывода: ник пира, изменение в количество пир поинтов
CREATE OR REPLACE PROCEDURE pr_change_points(in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        SELECT checking_peer AS peer, sum(points_amount) AS points_change
        FROM (SELECT checking_peer, sum(points_amount) AS points_amount
            FROM transferredpoints
            GROUP BY checking_peer
            UNION ALL
            SELECT checked_peer, sum(-points_amount) AS points_amount
            FROM transferredpoints
            GROUP BY checked_peer) AS change_points
        GROUP BY checking_peer
        ORDER BY points_change DESC;
END;
$$ language plpgsql;

BEGIN;
CALL pr_change_points('result');
FETCH ALL IN result;
END;
-- ===========================================================================================================================
--5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3
-- Результат вывести отсортированным по изменению числа поинтов.
-- Формат вывода: ник пира, изменение в количество пир поинтов

CREATE OR REPLACE PROCEDURE pr_change_points_from_fn(in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        SELECT peer_1 AS peer, sum(pointsamount) AS points_change
        FROM (SELECT peer_1, sum(points_amount) AS pointsamount
            FROM fn_transferred_points()
            GROUP BY peer_1
            UNION ALL
            SELECT peer_2, sum(-points_amount) AS pointsamount
            FROM fn_transferred_points()
            GROUP BY peer_2) AS change_points
        GROUP BY Peer
        ORDER BY points_change DESC;
END;
$$ language plpgsql;

BEGIN;
CALL pr_change_points_from_fn('result');
FETCH ALL IN result;
END;
-- ===========================================================================================================================
--6) Определить самое часто проверяемое задание за каждый день
-- При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все.
-- Формат вывода: день, название задания

CREATE OR REPLACE PROCEDURE pr_most_checked_task(in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH tmp AS (SELECT date, task, count(date) AS count
                    FROM checks
                    GROUP BY date, task
                    ORDER BY date)
        SELECT t1.date AS Day, t1.task
        FROM tmp t1
        LEFT JOIN tmp t2 ON t2.task != t1.task AND t2.date = t1.date
                                  AND t2.count < t1.count
        WHERE t2.date IS NULL;
END;
$$ language plpgsql;

BEGIN;
CALL pr_most_checked_task('result');
FETCH ALL IN result;
END;
-- ===========================================================================================================================
--7) Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
-- Параметры процедуры: название блока, например "CPP".
-- Результат вывести отсортированным по дате завершения.
-- Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)

CREATE OR REPLACE PROCEDURE pr_peers_complited_tasks_block(in result refcursor, in block_name varchar) AS
$$
BEGIN
     OPEN result FOR
        WITH tmp AS (SELECT * FROM tasks WHERE title_name SIMILAR TO concat(block_name, '[0-9]%')),
             check_name AS (SELECT max(title_name) AS title FROM tmp),
             check_date AS (SELECT peer, task, date
                            FROM checks c
                            JOIN p2p ON c.id = p2p.check_id
                            WHERE p2p.state = 'success')
        SELECT cd.peer AS Peer, to_char(date, 'dd.mm.yyyy') AS Day
        FROM check_date cd
        JOIN check_name cn ON cd.task = cn.title;
END;
$$ language plpgsql;

BEGIN;
CALL pr_peers_complited_tasks_block('result', 'C');
FETCH ALL IN result;
END;
-- ===========================================================================================================================
--8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
-- Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей.
-- Формат вывода: ник пира, ник найденного проверяющего

CREATE OR REPLACE PROCEDURE pr_rec_peers_for_checks(in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH friends_rec AS (SELECT peer1, peer2 AS friend FROM friends
                            UNION ALL
                            SELECT peer2, peer1 AS friend FROM friends),
            recs AS (SELECT distinct ON(peer1) peer1, recommended_peer, count(friend) AS count
                    FROM friends_rec fr
                    FULL JOIN recommendations r ON fr.friend = r.peer
                    WHERE peer1 != recommended_peer
                    GROUP BY peer1, recommended_peer
                    ORDER BY peer1, count DESC)
        SELECT peer1, recommended_peer FROM recs;
END;
$$ language plpgsql;

BEGIN;
CALL pr_rec_peers_for_checks('result');
FETCH ALL IN result;
END;
-- ===========================================================================================================================
--9) Определить процент пиров, которые:
-- Приступили только к блоку 1
-- Приступили только к блоку 2
-- Приступили к обоим
-- Не приступили ни к одному
-- Пир считается приступившим к блоку, если он проходил хоть одну проверку любого задания из этого блока (по таблице Checks)
-- Параметры процедуры: название блока 1, например SQL, название блока 2, например A.
-- Формат вывода: процент приступивших только к первому блоку, процент приступивших только ко второму блоку, процент приступивших к обоим, процент не приступивших ни к одному

CREATE OR REPLACE PROCEDURE pr_started_blocks(first_block varchar, second_block varchar, in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH block_1 AS (SELECT DISTINCT peer FROM checks WHERE task similar to concat(first_block, '[0-9]%')),
             block_2 AS (SELECT DISTINCT peer FROM checks WHERE task similar to concat(second_block, '[0-9]%')),
             blocks AS (SELECT DISTINCT peer FROM block_1
                        INTERSECT
                        SELECT DISTINCT peer FROM block_2),
             without_blocks AS (SELECT nickname AS peer FROM peers
                                EXCEPT
                                (SELECT DISTINCT peer FROM block_1
                                UNION
                                SELECT DISTINCT peer FROM block_2))
        SELECT (SELECT count(peer) FROM block_1) / (count(nickname) * 0.01) AS StartedBlock1,
               (SELECT count(peer) FROM block_2) / (count(nickname) * 0.01) AS StartedBlock2,
               (SELECT count(peer) FROM blocks) / (count(nickname) * 0.01) AS StartedBothBlocks,
               (SELECT count(peer) FROM without_blocks) / (count(nickname) * 0.01) AS DidntStartAnyBlock
        FROM peers;
END;
$$ language plpgsql;

BEGIN;
CALL pr_started_blocks('SQL', 'C', 'result');
FETCH ALL IN "result";
END;

-- INSERT INTO Tasks VALUES ('C_3DViewer_v1.0', NULL, 750);
-- INSERT INTO Tasks VALUES ('SQL1', 'C_3DViewer_v1.0', 1500);
-- INSERT INTO Tasks VALUES ('SQL2_Info21 v1.0', 'SQL1', 500);
-- INSERT INTO Checks (peer, task, date) VALUES ('Anti-Mage', 'C_3DViewer_v1.0', '2022-10-16');
-- INSERT INTO Checks (peer, task, date) VALUES ('Axe', 'C_3DViewer_v1.0', '2022-10-21');
-- INSERT INTO Checks (peer, task, date) VALUES ('Axe', 'SQL1', '2022-12-23');

-- ===========================================================================================================================
--10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
-- Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения.
-- Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения

CREATE OR REPLACE PROCEDURE pr_birthday_checks(in result refcursor) AS
$$
    BEGIN
        OPEN result FOR
        SELECT (SELECT count(*) * 100/ (SELECT count(*) FROM peers) FROM (SELECT DISTINCT nickname
                                    FROM peers
                                    JOIN checks ON nickname = peer
                                    AND  extract(MONTH FROM birthday) = extract(MONTH FROM "date")
                                    AND extract(DAY FROM birthday) = extract(DAY FROM "date")
                                    JOIN p2p ON checks.id = p2p.check_id
                                    WHERE p2p.state = 'success') a) AS SuccessfulChecks,
                (SELECT count(*) * 100/ (SELECT count(*) FROM peers) FROM (SELECT DISTINCT nickname
                                    FROM peers
                                    JOIN checks ON nickname = peer
                                    AND  extract(MONTH FROM birthday) = extract(MONTH FROM "date")
                                    AND extract(DAY FROM birthday) = extract(DAY FROM "date")
                                    JOIN p2p ON checks.id = p2p.check_id
                                    WHERE p2p.state = 'failure') b) AS UnsuccessfulChecks;
    END;
$$ language plpgsql;

BEGIN;
CALL pr_birthday_checks('result');
FETCH ALL IN result;
END;

-- INSERT INTO Checks (peer, task, date) VALUES ('Axe', 'C_3DViewer_v1.0', '2010-11-01');
-- INSERT INTO Verter (check_id, state, time) VALUES (15, 'start', '11:48');
-- INSERT INTO Verter (check_id, state, time) VALUES (15, 'success', '12:09');
-- INSERT INTO Checks (peer, task, date) VALUES ('Anti-Mage', 'C_3DViewer_v1.0', '2010-11-01');
-- INSERT INTO Verter (check_id, state, time) VALUES (16, 'start', '11:48');
-- INSERT INTO Verter (check_id, state, time) VALUES (16, 'success', '12:09');

-- ===========================================================================================================================
--11) Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
-- Параметры процедуры: названия заданий 1, 2 и 3.
-- Формат вывода: список пиров

CREATE OR REPLACE PROCEDURE pr_count_peers_passed_tasks_1_2(t1 varchar, t2 varchar, t3 varchar, in result refcursor) AS
$$
BEGIN
    OPEN result FOR
       WITH success_task AS (SELECT peer, task, xp_amount FROM checks
                            JOIN p2p on checks.id = p2p.check_id
                            JOIN xp on checks.id = xp.check_id
                            WHERE state = 'success'
                            ORDER BY peer),
         task1 AS (SELECT peer FROM success_task WHERE success_task.task LIKE t1),
         task2 AS (SELECT peer FROM success_task WHERE success_task.task LIKE t2),
         task3 AS (SELECT Peer FROM success_task WHERE success_task.task NOT LIKE t3)
       SELECT * FROM ((SELECT * FROM task1) INTERSECT (SELECT * FROM task2) INTERSECT (SELECT * FROM task3)) AS t;
END;
$$ language plpgsql;

BEGIN;
CALL pr_count_peers_passed_tasks_1_2('C2_SimpleBashUtils', 'C3_s21_string+', 'CPP2_s21_containers', 'result');
FETCH ALL IN result;
END;

-- BEGIN;
-- CALL pr_count_peers_passed_tasks_1_2('CPP2_s21_containers', 'A1_Maze', 'A2_SimpleNavigator_v1.0', 'result');
-- FETCH ALL IN result;
-- END;
-- ===========================================================================================================================
--12) Используя рекурсивное обобщенное табличное выражение, для каждой задачи вывести кол-во предшествующих ей задач
-- То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей.
-- Формат вывода: название задачи, количество предшествующих

CREATE OR REPLACE PROCEDURE pr_parent_tasks(task varchar,in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH RECURSIVE r AS (SELECT CASE
                                WHEN (tasks.parent_task IS NULL) THEN 0
                                ELSE 1
                            END AS counter,
                        tasks.title_name, tasks.parent_task AS current_tasks, tasks.parent_task
                    FROM tasks
                    UNION ALL
                    SELECT (CASE
                                WHEN child.parent_task IS NOT NULL THEN counter + 1
                                ELSE counter
                            END) AS counter,
                            child.title_name AS title,
                            child.parent_task AS current_tasks,
                            parrent.title_name AS parrenttask
                    FROM tasks AS child
                    CROSS JOIN r AS parrent
                    WHERE parrent.title_name LIKE child.parent_task)
        SELECT split_part(title_name, '_', 1)  AS Task, max(counter) AS PrevCount FROM r WHERE title_name LIKE concat(task, '%')
        GROUP BY title_name
        ORDER BY 1;

END;
$$ language plpgsql;

BEGIN;
CALL pr_parent_tasks('DO2', 'result');
FETCH ALL IN result;
END;

-- ===========================================================================================================================
--13) Найти "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы N идущих подряд успешных проверки
-- Параметры процедуры: количество идущих подряд успешных проверок N.
-- Временем проверки считать время начала P2P этапа.
-- Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных.
-- При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального.
-- Формат вывода: список дней

CREATE OR REPLACE PROCEDURE pr_secsessful_days_for_checks(n int, in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH tmp AS (SELECT c.id, date, peer, v.check_id, v.state
                    FROM checks c
                    JOIN p2p on c.id = p2p.check_id AND (p2p.state = 'success')
                    JOIN verter v on c.id = v.check_id AND (v.state = 'success')
                    ORDER BY date)
        SELECT date FROM tmp
        GROUP BY date
        HAVING count(date) >= n;
END;
$$ language plpgsql;

BEGIN;
CALL pr_secsessful_days_for_checks(2, 'result');
FETCH ALL IN result;
END;

-- ===========================================================================================================================
--14) Определить пира с наибольшим количеством XP
-- Формат вывода: ник пира, количество XP

CREATE OR REPLACE PROCEDURE pr_max_xp(in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH xp_count AS (SELECT peer AS peer, sum(xp_amount) AS xp FROM checks с
                    JOIN p2p ON с.id = p2p.check_id
                    JOIN xp ON с.id = xp.check_id
                    WHERE state = 'success'
                    GROUP BY peer
                    ORDER BY xp DESC)
        SELECT peer FROM xp_count
        WHERE xp = (SELECT max(xp) FROM xp_count)
        GROUP BY peer;
END;
$$ language plpgsql;

BEGIN;
CALL pr_max_xp('result');
FETCH ALL IN result;
END;

-- ===========================================================================================================================
--15) Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
-- Параметры процедуры: время, количество раз N.
-- Формат вывода: список пиров

CREATE OR REPLACE PROCEDURE pr_come_before_this_time(fix_time time, n int, in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        SELECT peer FROM timetracking
        WHERE (state = 1) AND (timetracking.time < fix_time)
        GROUP BY peer
        HAVING count(peer) > n;
END;
$$ language plpgsql;

BEGIN;
CALL pr_come_before_this_time('21:20:00', 1, 'result');
FETCH ALL IN result;
END;

-- ===========================================================================================================================
--16) Определить пиров, выходивших за последние N дней из кампуса больше M раз
-- Параметры процедуры: количество дней N, количество раз M.
-- Формат вывода: список пиров

CREATE OR REPLACE PROCEDURE pr_leaving_campus(n int, m int, in result refcursor) AS
$$
BEGIN
    OPEN result FOR
        WITH tmp AS (SELECT peer, date, count(*) AS count FROM timetracking
                    WHERE (state = 2) AND (date > (SELECT now()::date - n))
                    GROUP BY peer, date
                    ORDER BY date)
        SELECT peer FROM tmp
        GROUP BY peer
        HAVING sum(count) > m;
END;
$$ language plpgsql;

BEGIN;
CALL pr_leaving_campus(300, 1, 'result');
FETCH ALL IN result;
END;

-- ===========================================================================================================================
--17) Определить для каждого месяца процент ранних входов
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время (будем называть это общим числом входов).
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов).
-- Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов.
-- Формат вывода: месяц, процент ранних входов

CREATE OR REPLACE PROCEDURE pr_early_come_in(in result refcursor) AS
$$
BEGIN
    OPEN result FOR
         WITH birthdays AS (SELECT birthday::date, nickname, date_part('month', birthday)::numeric AS date_month, count(date) AS date_count
                            FROM peers
                            JOIN timetracking on peers.nickname = timetracking.peer
                            WHERE state = 1 AND time < '12:00:00'
                            GROUP BY nickname, date_part('month', birthday)::numeric
                            ORDER BY date_month),
         months AS (SELECT date_part('month', generate_series('2022-01-01', '2022-12-31', interval '1 month')::date) AS id,
                    to_char(generate_series('2022-01-01', '2022-12-31', interval '1 month')::date, 'Month') AS num, birthday,
                            date_part('month', birthday)::numeric AS date_month
                    FROM peers),
         all_times AS (SELECT DISTINCT m.birthday, num, id, sum(date_count) AS sum_count FROM months m
                    JOIN birthdays bd ON bd.date_month = m.date_month
                    WHERE id = m.date_month
                    GROUP BY m.birthday, num, id ORDER BY id)
    SELECT num AS Month, round(EarlyEntries * 100 / (SELECT count(date) FROM timetracking WHERE state = 1))
         FROM (SELECT id, num, sum(sum_count) AS EarlyEntries FROM all_times GROUP BY id, num) as foo;
END;
$$ language plpgsql;

BEGIN;
CALL pr_early_come_in('result');
FETCH ALL IN result;
END;