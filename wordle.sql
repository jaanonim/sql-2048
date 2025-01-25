CREATE UNLOGGED TABLE IF NOT EXISTS guesses (
    id SERIAL PRIMARY KEY,
    str char(5)
);

CREATE UNLOGGED TABLE IF NOT EXISTS target (
    str char(5)
);

CREATE OR REPLACE PROCEDURE print(str varchar) AS $$
BEGIN
    RAISE NOTICE '%', E'\033c' || str;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE play() AS $$
BEGIN
    DELETE FROM guesses;
    DELETE FROM target;
    
    -- set target to random word form words
    INSERT INTO target SELECT * FROM words 
    OFFSET (SELECT RANDOM(0,(SELECT count(*) FROM words)-1))
    LIMIT 1;

    -- insert places for guesses
    FOR i IN 1..6 LOOP
        INSERT INTO guesses VALUES (i,'_____');
    END LOOP;

    CALL display('');
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_letter_color(c char, i int) 
RETURNS varchar AS $$
BEGIN
    RETURN CASE 
        WHEN (SELECT SUBSTRING(str,i,1) = c FROM target) THEN E'\033[42m '
        WHEN (SELECT str ~ c FROM target) THEN E'\033[43m '
        ELSE E'\033[47m '
    END CASE;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE display(err varchar DEFAULT '') AS $$
DECLARE
    r record;
    frame varchar(1000) := '';
BEGIN 
    FOR r IN SELECT * FROM guesses ORDER BY id ASC LOOP
        FOR j IN 1..LENGTH(r.str) LOOP
            frame = frame || get_letter_color(SUBSTRING(r.str,j,1),j) ||
                UPPER(SUBSTRING(r.str,j,1)) || 
                E' \033[0m ';
            END LOOP;
        frame = frame || E'\n\n';
    END LOOP;
    frame = frame || E'\033[31m'||err||E'\033[0m';
    CALL print(frame);
END
$$ LANGUAGE plpgsql


CREATE OR REPLACE PROCEDURE play(guess varchar) AS $$
DECLARE 
    message varchar;
BEGIN
    guess = LOWER(TRIM(guess));
    IF NOT EXISTS(SELECT * FROM words w WHERE w.str = guess) THEN
        CALL display('Thats not a 5 letter word!');
    ELSE 
        UPDATE guesses SET str = guess 
        WHERE id = (
            SELECT id FROM guesses 
            WHERE str = '_____' ORDER BY id LIMIT 1
        );
        IF (SELECT str=guess FROM target) THEN 
            CALL display(E'You won!');
        ELSIF NOT EXISTS(SELECT id FROM guesses WHERE str = '_____') THEN
            message := E'You lost!\nWord was: "'||(SELECT UPPER(str) FROM target)||'"';
            CALL display(message);
        ELSE
            CALL display('');
        END IF;
       
    END IF;
END
$$ LANGUAGE plpgsql;
