DROP FUNCTION IF EXISTS init;
DROP TABLE IF EXISTS horizontal;
DROP TABLE IF EXISTS refrence;
DROP TABLE IF EXISTS info;

CREATE TABLE IF NOT EXISTS horizontal (
        A VARCHAR(255),
        B VARCHAR(255),
        C VARCHAR(255),
        D VARCHAR(255)
    );

CREATE TABLE IF NOT EXISTS refrence (
        r integer NOT NULL,
        c integer NOT NULL,
        val VARCHAR(255)
    );

CREATE OR REPLACE FUNCTION init()
RETURNS TABLE (A VARCHAR(255), B VARCHAR(255), C VARCHAR(255), D VARCHAR(255)) AS
$$
BEGIN
    DELETE FROM horizontal;
    INSERT INTO horizontal (A, B, C, D)
    VALUES ('', '', '', ''),
        ('', '', '', ''),
        ('', '', '', ''),
        ('', '', '', '');
    CALL horizontal_to_refrence();
    CALL insert_random();
    CALL insert_random();
    CALL refrence_to_horizontal();
    
    RETURN QUERY SELECT * FROM horizontal;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE horizontal_to_refrence()
LANGUAGE SQL
BEGIN ATOMIC
    DELETE FROM refrence;
    INSERT INTO refrence (r,c,val) VALUES 
        (1,1,(SELECT A FROM horizontal LIMIT 1 OFFSET 0)),
        (1,2,(SELECT B FROM horizontal LIMIT 1 OFFSET 0)),
        (1,3,(SELECT C FROM horizontal LIMIT 1 OFFSET 0)),
        (1,4,(SELECT D FROM horizontal LIMIT 1 OFFSET 0)),
        (2,1,(SELECT A FROM horizontal LIMIT 1 OFFSET 1)),
        (2,2,(SELECT B FROM horizontal LIMIT 1 OFFSET 1)),
        (2,3,(SELECT C FROM horizontal LIMIT 1 OFFSET 1)),
        (2,4,(SELECT D FROM horizontal LIMIT 1 OFFSET 1)),
        (3,1,(SELECT A FROM horizontal LIMIT 1 OFFSET 2)),
        (3,2,(SELECT B FROM horizontal LIMIT 1 OFFSET 2)),
        (3,3,(SELECT C FROM horizontal LIMIT 1 OFFSET 2)),
        (3,4,(SELECT D FROM horizontal LIMIT 1 OFFSET 2)),
        (4,1,(SELECT A FROM horizontal LIMIT 1 OFFSET 3)),
        (4,2,(SELECT B FROM horizontal LIMIT 1 OFFSET 3)),
        (4,3,(SELECT C FROM horizontal LIMIT 1 OFFSET 3)),
        (4,4,(SELECT D FROM horizontal LIMIT 1 OFFSET 3))
    ;
END;

CREATE OR REPLACE PROCEDURE refrence_to_horizontal()
LANGUAGE SQL
BEGIN ATOMIC
    DELETE FROM horizontal;
    INSERT INTO horizontal (A, B, C, D) VALUES (
        (SELECT val FROM refrence WHERE r = 1 AND c = 1),
        (SELECT val FROM refrence WHERE r = 1 AND c = 2),
        (SELECT val FROM refrence WHERE r = 1 AND c = 3),
        (SELECT val FROM refrence WHERE r = 1 AND c = 4)
    );
    INSERT INTO horizontal (A, B, C, D) VALUES (
        (SELECT val FROM refrence WHERE r = 2 AND c = 1),
        (SELECT val FROM refrence WHERE r = 2 AND c = 2),
        (SELECT val FROM refrence WHERE r = 2 AND c = 3),
        (SELECT val FROM refrence WHERE r = 2 AND c = 4)
    );
    INSERT INTO horizontal (A, B, C, D) VALUES (
        (SELECT val FROM refrence WHERE r = 3 AND c = 1),
        (SELECT val FROM refrence WHERE r = 3 AND c = 2),
        (SELECT val FROM refrence WHERE r = 3 AND c = 3),
        (SELECT val FROM refrence WHERE r = 3 AND c = 4)
    );
    INSERT INTO horizontal (A, B, C, D) VALUES (
        (SELECT val FROM refrence WHERE r = 4 AND c = 1),
        (SELECT val FROM refrence WHERE r = 4 AND c = 2),
        (SELECT val FROM refrence WHERE r = 4 AND c = 3),
        (SELECT val FROM refrence WHERE r = 4 AND c = 4)
    );
END;

CREATE OR REPLACE FUNCTION count_of_empty()
RETURNS INTEGER AS $$
SELECT count(*) FROM refrence WHERE val = '';
$$ LANGUAGE SQL;

CREATE OR REPLACE PROCEDURE insert_random()
LANGUAGE SQL
BEGIN ATOMIC
    UPDATE refrence SET val = (CASE WHEN random() > 0.9 THEN '4' ELSE '2' END) 
    WHERE r+10*c = (
        SELECT r+10*c 
        FROM refrence 
        WHERE val='' 
        LIMIT 1 
        OFFSET (SELECT FLOOR(count_of_empty() * RANDOM()) ::int
    ));
    SELECT * FROM refrence;
END;

CREATE OR REPLACE FUNCTION can_make_move()
RETURNS BOOLEAN AS $$
BEGIN
    CASE WHEN (count_of_empty()>0) THEN
        RETURN TRUE;
    ELSE
        FOR i IN 1..4 LOOP
            FOR j IN 1..4 LOOP
                IF check_move(i, j) THEN
                    RETURN TRUE;
                END IF;
            END LOOP;
        END LOOP;
        RETURN FALSE;
    END CASE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_move(x INTEGER, y INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    center VARCHAR(255);
    lf VARCHAR(255);
    rt VARCHAR(255);
    up VARCHAR(255);
    dn VARCHAR(255);
BEGIN
    center := (SELECT val FROM refrence WHERE r = x AND c = y);
    lf := (SELECT val FROM refrence WHERE r = x AND c = y+1);
    rt := (SELECT val FROM refrence WHERE r = x AND c = y-1);
    up := (SELECT val FROM refrence WHERE r = x-1 AND c = y);
    dn := (SELECT val FROM refrence WHERE r = x+1 AND c = y);
    RETURN (SELECT center=lf OR center=rt OR center=up OR center=dn);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE colapse_fix() AS $$
BEGIN
    UPDATE refrence SET val=RIGHT(val,LENGTH(val)-1) WHERE val LIKE 'm%';
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE call_move(move_name text) AS $$
BEGIN
    CREATE TABLE refrence_back AS TABLE refrence;

    FOR i IN 1..4 LOOP
        FOR j IN 1..3 LOOP
            FOR k IN 1..3 LOOP
                EXECUTE 'CALL colapse_' || move_name || '('||i||', '||k||')';
            END LOOP;
        END LOOP;
    END LOOP;
    CALL colapse_fix();

    
    CASE WHEN (SELECT count(*)>0 
        FROM (SELECT * FROM refrence EXCEPT SELECT * FROM refrence_back)) 
    THEN
        CALL insert_random();
        DROP TABLE refrence_back;
    ELSE
        DROP TABLE refrence_back;
    END CASE;
    CALL refrence_to_horizontal();
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION display()
RETURNS TABLE (A VARCHAR(255), B VARCHAR(255), C VARCHAR(255), D VARCHAR(255)) AS
$$
BEGIN
    CASE WHEN can_make_move() THEN
        RETURN QUERY SELECT * FROM horizontal;
    ELSE
        RETURN QUERY SELECT 'You Lost!'::VARCHAR(255),'Score:'::VARCHAR(255), (SELECT sum(val::INTEGER) FROM refrence)::VARCHAR(255),'Run SELECT * FROM init(); to restart.'::VARCHAR(255);
    END CASE;
END;
$$
LANGUAGE plpgsql;

-------------------------------------------------

CREATE OR REPLACE PROCEDURE colapse_left(x INTEGER, y INTEGER) AS $$
DECLARE
    f VARCHAR(255);
    s VARCHAR(255);
BEGIN
    f := (SELECT val FROM refrence WHERE r=x AND c=y);
    s := (SELECT val FROM refrence WHERE r=x AND c=y+1);

    UPDATE refrence SET val=( 
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN concat('m',s::INTEGER + f::INTEGER)
            ELSE s
            END)
        ELSE f
        END)
    WHERE r=x AND c=y;

    
    UPDATE refrence SET val=(
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN ''
            ELSE f
            END)
        ELSE s
        END)
    WHERE r=x AND c=y+1;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE colapse_right(x INTEGER, y INTEGER) AS $$
DECLARE
    f VARCHAR(255);
    s VARCHAR(255);
BEGIN
    f := (SELECT val FROM refrence WHERE r=x AND c=5-y);
    s := (SELECT val FROM refrence WHERE r=x AND c=4-y);

    UPDATE refrence SET val=( 
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN concat('m',s::INTEGER + f::INTEGER)
            ELSE s
            END)
        ELSE f
        END)
    WHERE r=x AND c=5-y;

    
    UPDATE refrence SET val=(
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN ''
            ELSE f
            END)
        ELSE s
        END)
    WHERE r=x AND c=4-y;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE colapse_up(y INTEGER, x INTEGER) AS $$
DECLARE
    f VARCHAR(255);
    s VARCHAR(255);
BEGIN
    f := (SELECT val FROM refrence WHERE r=x AND c=y);
    s := (SELECT val FROM refrence WHERE r=x+1 AND c=y);

    UPDATE refrence SET val=( 
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN concat('m',s::INTEGER + f::INTEGER)
            ELSE s
            END)
        ELSE f
        END)
    WHERE r=x AND c=y;

    
    UPDATE refrence SET val=(
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN ''
            ELSE f
            END)
        ELSE s
        END)
    WHERE r=x+1 AND c=y;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE colapse_down(y INTEGER, x INTEGER) AS $$
DECLARE
    f VARCHAR(255);
    s VARCHAR(255);
BEGIN
    f := (SELECT val FROM refrence WHERE r=5-x AND c=y);
    s := (SELECT val FROM refrence WHERE r=4-x AND c=y);

    UPDATE refrence SET val=( 
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN concat('m',s::INTEGER + f::INTEGER)
            ELSE s
            END)
        ELSE f
        END)
    WHERE r=5-x AND c=y;

    
    UPDATE refrence SET val=(
        CASE WHEN f = s OR f = ''
        THEN (CASE WHEN f!='' AND s!=''
            THEN ''
            ELSE f
            END)
        ELSE s
        END)
    WHERE r=4-x AND c=y;
END;
$$
LANGUAGE plpgsql;

-------------------------------------------------

CREATE OR REPLACE FUNCTION left()
RETURNS TABLE (A VARCHAR(255), B VARCHAR(255), C VARCHAR(255), D VARCHAR(255)) AS
$$
BEGIN
    CALL call_move('left');
    RETURN QUERY SELECT * FROM display();
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION right()
RETURNS TABLE (A VARCHAR(255), B VARCHAR(255), C VARCHAR(255), D VARCHAR(255)) AS
$$
BEGIN
    CALL call_move('right');
    RETURN QUERY SELECT * FROM horizontal;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION down()
RETURNS TABLE (A VARCHAR(255), B VARCHAR(255), C VARCHAR(255), D VARCHAR(255)) AS
$$
BEGIN
    CALL call_move('down');
    RETURN QUERY SELECT * FROM horizontal;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION up()
RETURNS TABLE (A VARCHAR(255), B VARCHAR(255), C VARCHAR(255), D VARCHAR(255)) AS
$$
BEGIN
    CALL call_move('up');
    RETURN QUERY SELECT * FROM horizontal;
END;
$$
LANGUAGE plpgsql;

-------------------------------------------------

CREATE TABLE IF NOT EXISTS info (
        sql2048 VARCHAR(255)
    );
INSERT INTO info (sql2048) VALUES 
    ('2048 SQL'),
    (''),
    ('To start game run:') ,
    ('SELECT * FROM init();'),
    (''),
    ('Controls:'),
    ('SELECT * FROM left();'),
    ('SELECT * FROM right();'),
    ('SELECT * FROM up();'),
    ('SELECT * FROM down();')
;

SELECT * FROM info;