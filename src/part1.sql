--Part1
-- DROP DATABASE info_21;

CREATE DATABASE info_21;

-- DROP SCHEMA IF EXISTS public CASCADE;
-- CREATE SCHEMA IF NOT EXISTS public AUTHORIZATION public;

-- DROP TABLE IF EXISTS Tasks, P2P, Verter, Checks, Xp, Peers,
--     TransferredPoints, Friends, Recommendations, TimeTracking CASCADE;

CREATE TABLE IF NOT EXISTS Peers (
    nickname VARCHAR PRIMARY KEY,
    birthday DATE NOT NULL
);

--DROP TABLE Peers;

INSERT INTO Peers VALUES ('Anti-Mage', '2010-11-01');
INSERT INTO Peers VALUES ('Axe', '2010-11-01');
INSERT INTO Peers VALUES ('Crystal Maiden', '2010-11-01');
INSERT INTO Peers VALUES ('Slardar', '2011-01-18');
INSERT INTO Peers VALUES ('Enigma', '2011-02-12');
INSERT INTO Peers VALUES ('Faceless Void', '2011-02-19');
INSERT INTO Peers VALUES ('Chen', '2011-07-01');
INSERT INTO Peers VALUES ('Invoker', '2012-01-19');

CREATE TABLE IF NOT EXISTS Tasks (
    title_name  varchar NOT NULL PRIMARY KEY,
    parent_task varchar NULL REFERENCES Tasks(title_name),
    max_xp int NOT NULL
);

--DROP TABLE Tasks;

INSERT INTO Tasks VALUES ('CPP1_s21_matrix+', NULL, 300);
INSERT INTO Tasks VALUES ('CPP2_s21_containers', 'CPP1_s21_matrix+', 350);
INSERT INTO Tasks VALUES ('CPP3_SmartCalc_v2.0', 'CPP2_s21_containers', 600);
INSERT INTO Tasks VALUES ('A1_Maze', 'CPP3_SmartCalc_v2.0', 300);
INSERT INTO Tasks VALUES ('A2_SimpleNavigator_v1.0', 'A1_Maze', 400);
INSERT INTO Tasks VALUES ('A3_Parallels', 'A2_SimpleNavigator_v1.0', 300);

CREATE TABLE IF NOT EXISTS Checks (
    id BIGSERIAL PRIMARY KEY,
    peer varchar NOT NULL REFERENCES Peers (nickname),
    task varchar NOT NULL REFERENCES Tasks(title_name),
    Date DATE NOT NULL
);

--DROP TABLE Checks;

INSERT INTO Checks (peer, task, date) VALUES ('Anti-Mage', 'CPP1_s21_matrix+', '2022-12-16');
INSERT INTO Checks (peer, task, date) VALUES ('Axe', 'CPP2_s21_containers', '2022-12-16');
INSERT INTO Checks (peer, task, date) VALUES ('Crystal Maiden', 'CPP2_s21_containers', '2022-12-16');
INSERT INTO Checks (peer, task, date) VALUES ('Crystal Maiden', 'A1_Maze', '2022-12-17');
INSERT INTO Checks (peer, task, date) VALUES ('Slardar', 'CPP3_SmartCalc_v2.0', '2022-12-17');
INSERT INTO Checks (peer, task, date) VALUES ('Enigma', 'CPP3_SmartCalc_v2.0', '2022-12-17');
INSERT INTO Checks (peer, task, date) VALUES ('Enigma', 'CPP1_s21_matrix+', '2022-12-16');
INSERT INTO Checks (peer, task, date) VALUES ('Faceless Void', 'CPP2_s21_containers', '2022-12-24');
INSERT INTO Checks (peer, task, date) VALUES ('Faceless Void', 'A1_Maze', '2023-01-12');
INSERT INTO Checks (peer, task, date) VALUES ('Enigma', 'A1_Maze', '2023-03-14');
INSERT INTO Checks (peer, task, date) VALUES ('Chen', 'A2_SimpleNavigator_v1.0', '2023-05-16');

-- CREATE TYPE Check_status AS ENUM ('start', 'success', 'failure');

-- DROP TYPE Check_status CASCADE;

CREATE TABLE IF NOT EXISTS P2P (
    id BIGSERIAL PRIMARY KEY,
    check_id bigint REFERENCES Checks (id),
    checking_peer VARCHAR NOT NULL REFERENCES Peers (nickname),
    state Check_status NOT NULL,
    time TIME NOT NULL,
    UNIQUE (check_id, checking_peer, state)
);

-- DROP TABLE P2P;

INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (1, 'Anti-Mage', 'start', '20:30');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (1, 'Anti-Mage', 'success', '21:04');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (2, 'Axe', 'start', '13:03');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (2, 'Axe', 'success', '13:37');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (3, 'Crystal Maiden', 'start', '08:17');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (3, 'Crystal Maiden', 'success', '09:03');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (4, 'Anti-Mage', 'start', '00:00');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (4, 'Anti-Mage', 'success', '00:44');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (5, 'Enigma', 'start', '17:01');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (5, 'Enigma', 'success', '17:48');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (6, 'Enigma', 'start', '11:32');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (6, 'Enigma', 'success', '12:13');
insert into P2P (check_id, checking_peer, state, time) VALUES (7, 'Faceless Void', 'start', '21:00:29');
insert into P2P (check_id, checking_peer, state, time) VALUES (7, 'Faceless Void', 'success', '21:31:57');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (9, 'Anti-Mage', 'start', '08:30');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (9, 'Anti-Mage', 'success', '09:12');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (10, 'Crystal Maiden', 'start', '18:30');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (10, 'Crystal Maiden', 'failure', '19:12');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (11, 'Crystal Maiden', 'start', '10:12');
INSERT INTO P2P (check_id, checking_peer, state, time) VALUES (11, 'Crystal Maiden', 'success', '11:02');

CREATE TABLE IF NOT EXISTS Verter (
    id BIGSERIAL PRIMARY KEY,
    check_id bigint REFERENCES Checks (id),
    state Check_status NOT NULL,
    time TIME NOT NULL,
    UNIQUE (check_id, state)
);

--DROP TABLE Verter;

INSERT INTO Verter (check_id, state, time) VALUES (1, 'start', '21:05');
INSERT INTO Verter (check_id, state, time) VALUES (1, 'success', '21:07');
INSERT INTO Verter (check_id, state, time) VALUES (2, 'start', '13:37');
INSERT INTO Verter (check_id, state, time) VALUES (2, 'success', '13:38');
INSERT INTO Verter (check_id, state, time) VALUES (3, 'start', '09:03');
INSERT INTO Verter (check_id, state, time) VALUES (3, 'success', '09:04');
INSERT INTO Verter (check_id, state, time) VALUES (4, 'start', '00:44');
INSERT INTO Verter (check_id, state, time) VALUES (4, 'success', '00:45');
INSERT INTO Verter (check_id, state, time) VALUES (5, 'start', '17:48');
INSERT INTO Verter (check_id, state, time) VALUES (5, 'success', '17:49');
INSERT INTO Verter (check_id, state, time) VALUES (7, 'start', '06:57');
INSERT INTO Verter (check_id, state, time) VALUES (7, 'success', '06:58');
INSERT INTO Verter (check_id, state, time) VALUES (8, 'start', '07:47');
INSERT INTO Verter (check_id, state, time) VALUES (8, 'success', '07:49');
INSERT INTO Verter (check_id, state, time) VALUES (9, 'start', '17:48');
INSERT INTO Verter (check_id, state, time) VALUES (9, 'failure', '17:49');
INSERT INTO Verter (check_id, state, time) VALUES (11, 'start', '11:48');
INSERT INTO Verter (check_id, state, time) VALUES (11, 'success', '12:09');

CREATE TABLE IF NOT EXISTS Xp (
    id BIGSERIAL PRIMARY KEY,
    check_id  bigint REFERENCES Checks (id) UNIQUE,
    xp_amount integer NOT NULL CHECK ( xp_amount > 0 )
);

--DROP TABLE Xp;

INSERT INTO Xp (check_id, xp_amount) VALUES (1, 280);
INSERT INTO Xp (check_id, xp_amount) VALUES (2, 350);
INSERT INTO Xp (check_id, xp_amount) VALUES (3, 350);
INSERT INTO Xp (check_id, xp_amount) VALUES (4, 300);
INSERT INTO Xp (check_id, xp_amount) VALUES (5, 550);
INSERT INTO Xp (check_id, xp_amount) VALUES (6, 600);
INSERT INTO Xp (check_id, xp_amount) VALUES (7, 300);
INSERT INTO Xp (check_id, xp_amount) VALUES (11, 400);

CREATE TABLE IF NOT EXISTS TransferredPoints (
    id BIGSERIAL PRIMARY KEY,
    checking_peer  VARCHAR NOT NULL REFERENCES Peers (nickname),
    checked_peer  VARCHAR NOT NULL REFERENCES Peers (nickname),
    points_amount integer NOT NULL CHECK ( points_amount > 0 ),
    UNIQUE (checking_peer, checked_peer)
);

-- DROP TABLE TransferredPoints;

INSERT INTO TransferredPoints (checking_peer, checked_peer, points_amount) VALUES ('Anti-Mage', 'Axe', 1);
insert into TransferredPoints (checking_peer, checked_peer, points_amount) values ('Axe', 'Anti-Mage', 5);
INSERT INTO TransferredPoints (checking_peer, checked_peer, points_amount) VALUES ('Crystal Maiden', 'Anti-Mage', 3);
insert into TransferredPoints (checking_peer, checked_peer, points_amount) values ('Enigma', 'Crystal Maiden', 7);
INSERT INTO TransferredPoints (checking_peer, checked_peer, points_amount) VALUES ('Faceless Void', 'Chen', 2);
insert into TransferredPoints (checking_peer, checked_peer, points_amount) values ('Chen', 'Faceless Void', 4);
INSERT INTO TransferredPoints (checking_peer, checked_peer, points_amount) VALUES ('Crystal Maiden', 'Chen', 3);
INSERT INTO TransferredPoints (checking_peer, checked_peer, points_amount) VALUES ('Axe', 'Faceless Void', 1);

CREATE TABLE IF NOT EXISTS Friends (
    id BIGSERIAL PRIMARY KEY,
    peer1 VARCHAR NOT NULL REFERENCES Peers (nickname),
    peer2 VARCHAR NOT NULL REFERENCES Peers (nickname),
    UNIQUE (peer1, peer2)
);

-- DROP TABLE Friends;

INSERT INTO Friends (peer1, peer2) VALUES ('Anti-Mage', 'Enigma');
INSERT INTO Friends (peer1, peer2) VALUES ('Anti-Mage', 'Faceless Void');
INSERT INTO Friends (peer1, peer2) VALUES ('Axe', 'Enigma');
INSERT INTO Friends (peer1, peer2) VALUES ('Faceless Void', 'Enigma');
INSERT INTO Friends (peer1, peer2) VALUES ('Axe', 'Faceless Void');
INSERT INTO Friends (peer1, peer2) VALUES ('Anti-Mage', 'Axe');
INSERT INTO Friends (peer1, peer2) VALUES ('Axe', 'Crystal Maiden');
INSERT INTO Friends (peer1, peer2) VALUES ('Anti-Mage', 'Crystal Maiden');

CREATE TABLE IF NOT EXISTS Recommendations (
    id BIGSERIAL PRIMARY KEY,
    peer VARCHAR NOT NULL REFERENCES Peers (nickname),
    recommended_peer varchar NOT NULL REFERENCES Peers (nickname) CHECK ( recommended_peer <> peer ),
    UNIQUE (peer, recommended_peer)
);

-- DROP TABLE Recommendations;

INSERT INTO Recommendations (peer, recommended_peer) VALUES ('Anti-Mage', 'Enigma');
INSERT INTO Recommendations (peer, recommended_peer) VALUES ('Axe', 'Crystal Maiden');
INSERT INTO Recommendations (peer, recommended_peer) VALUES ('Faceless Void', 'Crystal Maiden');
INSERT INTO Recommendations (peer, recommended_peer) VALUES ('Crystal Maiden', 'Chen');
INSERT INTO Recommendations (peer, recommended_peer) VALUES ('Chen', 'Enigma');
INSERT INTO Recommendations (peer, recommended_peer) VALUES ('Chen', 'Crystal Maiden');

CREATE TABLE IF NOT EXISTS TimeTracking (
    id BIGSERIAL PRIMARY KEY,
    peer  VARCHAR NOT NULL REFERENCES Peers (nickname),
    date  DATE NOT NULL,
    time  TIME NOT NULL,
    state integer NOT NULL CHECK ( state IN (1, 2) ),
    UNIQUE (peer, date, time)
);

-- DROP TABLE TimeTracking;

INSERT INTO TimeTracking (peer, date, time, state) VALUES ('Chen', '2022-12-01', '15:00', 1);
INSERT INTO TimeTracking (peer, date, time, state) VALUES ('Chen', '2022-12-01', '18:43', 2);
INSERT INTO TimeTracking (peer, date, time, state) VALUES ('Chen', '2022-12-01', '19:50', 1);
INSERT INTO TimeTracking (peer, date, time, state) VALUES ('Chen', '2022-12-01', '23:23', 2);
INSERT INTO TimeTracking (peer, date, time, state) VALUES ('Faceless Void', '2022-12-01', '07:00', 1);
INSERT INTO TimeTracking (peer, date, time, state) VALUES ('Faceless Void', '2022-12-01', '14:00', 2);
INSERT INTO TimeTracking(peer, date, time, state) VALUES ('Axe', '2022-12-28', '11:59', 1);
INSERT INTO TimeTracking(peer, date, time, state) VALUES ('Axe', '2022-12-28', '16:00', 2);
INSERT INTO TimeTracking(peer, date, time, state) VALUES ('Anti-Mage', now()::date, '10:00', 1);
INSERT INTO TimeTracking(peer, date, time, state) VALUES ('Anti-Mage', now()::date, '16:00', 2);

CREATE OR REPLACE PROCEDURE Export (
    table_name VARCHAR(50),
    source VARCHAR(100),
    delimiter VARCHAR(5) DEFAULT ',')
    LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I FROM %L WITH DELIMITER %L CSV HEADER', table_name, source, delimiter);
END;
$$;

-- CALL export('tasks', '/home/student/for_sql/tasks.csv');

CREATE OR REPLACE PROCEDURE Import(
    table_name VARCHAR(50),
    source VARCHAR(100),
    delimiter VARCHAR(5) DEFAULT ',')
    LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE format('COPY %I FROM %L WITH DELIMITER %L CSV HEADER', table_name, source, delimiter);
END;
$$;


-- CALL import('peers', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/peers.csv');
-- CALL import('tasks', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/tasks.csv');
-- CALL import('checks', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/checks.csv');
-- CALL import('p2p', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/p2p.csv');
-- CALL import('verter', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/verter.csv');
-- CALL import('xp', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/xp.csv');
-- CALL import('transferredpoints', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/transferredpoints.csv');
-- CALL import('friends', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/friends.csv');
-- CALL import('recommendations', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/recommendations.csv');
-- CALL import('timetracking', '/Users/leggeedi/SQL2_Info21_v1.0-2/src/for import/timetracking.csv');
