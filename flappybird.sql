DROP TABLE IF EXISTS bird;
DROP TABLE IF EXISTS blocks;
DROP TABLE IF EXISTS commands;
DROP TABLE IF EXISTS config;
DROP TABLE IF EXISTS score;

CREATE UNLOGGED TABLE IF NOT EXISTS bird (
    x INTEGER,
    y INTEGER,
    velocity INTEGER
);


CREATE UNLOGGED TABLE IF NOT EXISTS score (
    score INTEGER
);

CREATE UNLOGGED TABLE IF NOT EXISTS blocks (
    x INTEGER,
    hole_y INTEGER,
    height INTEGER
);

CREATE UNLOGGED TABLE IF NOT EXISTS commands (
    v INTEGER   
);

CREATE UNLOGGED TABLE IF NOT EXISTS config (
    start_x INTEGER,
    start_y INTEGER,
    gravity INTEGER,
    jump INTEGER,
    block_width INTEGER,
    screen_width INTEGER,
    screen_height INTEGER,
    update_rate FLOAT,
    spawn_distnace INTEGER,
    block_height INTEGER
);

DELETE FROM config;
INSERT INTO config (start_x, start_y, gravity, jump, block_width, screen_width, screen_height, update_rate, spawn_distnace, block_height)
VALUES              (3,         7,      1,      -2,         2,      50,             14,         0.5,             15,           4);

CREATE or replace PROCEDURE init_f()
language plpgsql AS $$
BEGIN
    DELETE FROM bird;
    DELETE FROM blocks;
    DELETE FROM commands;
    DELETE FROM score;

    INSERT INTO score (score) VALUES (0);

    INSERT INTO bird (x, y, velocity)
    VALUES (
        (SELECT start_x FROM config), 
        (SELECT start_y FROM config), 
        0
    );
END 
$$;


CREATE or replace PROCEDURE spawn_wall()
language plpgsql AS $$
BEGIN
    INSERT INTO blocks (x,hole_y,height)
    VALUES (
        (SELECT screen_width FROM config),
        (FLOOR(RANDOM() * ((SELECT screen_height FROM config) - 6)) + 2),
        (SELECT block_height FROM config)
    );
END
$$;


CREATE or replace PROCEDURE update_wall()
language plpgsql AS $$
BEGIN
    UPDATE blocks SET x=x-1;
    UPDATE score SET score = score + (SELECT count(*) FROM blocks WHERE x < 0);
    DELETE FROM blocks WHERE x<0;
END
$$;


CREATE or replace PROCEDURE update_bird()
language plpgsql AS $$
BEGIN

    IF (SELECT velocity FROM bird) >= 0 AND (SELECT count(*) > 0 FROM commands) THEN
        UPDATE bird
        SET velocity = (SELECT jump FROM config);
        DELETE FROM commands;
    ELSE
        UPDATE bird
        SET y = y + GREATEST(LEAST(velocity,1),-1);
        UPDATE bird
        SET velocity = LEAST(velocity + (SELECT gravity FROM config), 2);
    END IF;
END
$$;

CREATE or replace FUNCTION draw_bird(x INTEGER, y INTEGER)
RETURNS TEXT language plpgsql AS $$
BEGIN
    IF x = (SELECT bird.x FROM bird) AND y = (SELECT bird.y FROM bird) THEN
        RETURN E'\033[31m'||'>'||E'\033[0m';
    END IF;
    IF x = (SELECT bird.x FROM bird)-1 AND y = (SELECT bird.y FROM bird) THEN
        RETURN E'\033[33m'||'O'||E'\033[0m';
    END IF;
    IF x = (SELECT bird.x FROM bird)-2 AND y = (SELECT bird.y FROM bird) THEN
        IF (SELECT velocity FROM bird) < 0 THEN
            RETURN E'\033[33m'||'/'||E'\033[0m';
        END IF;
        IF (SELECT velocity FROM bird) > 1 THEN
            RETURN E'\033[33m'||E'\\'||E'\033[0m';
        END IF;
        RETURN E'\033[33m'||'-'||E'\033[0m';
    END IF;
    RETURN ' ';
END
$$;

CREATE or replace FUNCTION draw_block(x INTEGER, y INTEGER)
RETURNS TEXT language plpgsql AS $$
DECLARE
    ele record;
    width INTEGER;
BEGIN
    
    width := (SELECT block_width FROM config);
    IF (SELECT count(*) FROM blocks) = 0 THEN
        RETURN ' ';
    END IF;
    
    FOR ele IN SELECT * FROM blocks LOOP
        IF (ele.x <= x AND ele.x + width >= x) THEN
            IF (y < ele.hole_y OR y > ele.hole_y + ele.height) THEN
                RETURN E'\033[32m'||'#'||E'\033[0m';
            ELSE
                RETURN ' ';
            END IF;
        END IF;
    END LOOP;
    RETURN ' ';
END
$$;

CREATE or replace PROCEDURE jump()
language plpgsql AS $$
BEGIN
    INSERT INTO commands (v)
    VALUES (1);
END
$$;

CREATE or replace FUNCTION get_key(k TEXT)
RETURNS TEXT language plpgsql AS $$
BEGIN
    IF k = '[A' THEN
        CALL jump();
        RETURN 'Jump!';
    END IF;
    RETURN 'Unused key: "' || k || '"';
END
$$;


CREATE or replace FUNCTION draw()
RETURNS TEXT language plpgsql AS $$
DECLARE
    frame TEXT := '';
    val TEXT := ' ';
BEGIN
    FOR y IN 1..(SELECT screen_height FROM config) LOOP
        FOR x IN 1..(SELECT screen_width FROM config) LOOP
            val := ' ';
            val := draw_bird(x, y);
            IF val = ' ' THEN
               val := draw_block(x, y);
            END IF;
            frame := frame || val;
        END LOOP;
        frame := frame || E'\n';
    END LOOP;
    RETURN frame;
END
$$;

CREATE or replace FUNCTION check_colisions()
RETURNS BOOLEAN language plpgsql AS $$
DECLARE
    ele record;
    width INTEGER  := (SELECT block_width FROM config);
    x INTEGER := (SELECT bird.x FROM bird);
    y INTEGER := (SELECT bird.y FROM bird);
BEGIN
    
    FOR ele IN SELECT * FROM blocks LOOP
        IF (ele.x <= x AND ele.x + width >= x) THEN
            IF (y < ele.hole_y OR y > ele.hole_y + ele.height) THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    END LOOP;
    RETURN FALSE;
END
$$;



CREATE or replace FUNCTION is_game_over()
RETURNS BOOLEAN language plpgsql AS $$
BEGIN
    RETURN (
        (SELECT y FROM bird) > (SELECT screen_height FROM config) 
        OR (SELECT y FROM bird) < 0
        OR check_colisions()
    );
END
$$;



CREATE or replace PROCEDURE start()
language plpgsql AS $$
DECLARE
    update_time FLOAT := 0;
    spawn_time FLOAT := (SELECT update_rate * spawn_distnace FROM config);
    delta_time FLOAT := 0.1;
    frame TEXT := '';
    start_time TIMESTAMP := clock_timestamp();
BEGIN
    CALL init_f();
    LOOP
        start_time := clock_timestamp();
       
        IF update_time >= (SELECT update_rate FROM config) THEN
            update_time := 0;
            CALL update_bird();
            CALL update_wall();
        END IF;

        IF spawn_time >= (SELECT spawn_distnace * update_rate FROM config) THEN
            spawn_time := 0;
            CALL spawn_wall();
        END IF;

        
        frame := draw();

        IF is_game_over() THEN
            EXIT;
        END IF;

        frame := frame || repeat('-'::TEXT, (SELECT screen_width FROM config)/2 - 2) ;
        frame := frame || E'\033[36m ' || (SELECT score FROM score) || E'\033[0m ';
        frame := frame || repeat('-'::TEXT, (SELECT screen_width FROM config)/2 - 1);

        -- Draw and wait
        RAISE NOTICE '%', E'\033c' || frame ;

        delta_time := EXTRACT(SECOND FROM clock_timestamp() - start_time);

        -- PERFORM pg_sleep(0.1);
        -- Update time
        update_time := update_time + delta_time;
        spawn_time := spawn_time + delta_time;
    END LOOP;
    RAISE NOTICE '%', E'\033c' || E'\033[31mGAME OVER \033[0m \n You are looser!\n You score is: \033[36m'|| (SELECT score FROM score)||E'\033[0m';
END
$$;


SELECT 'Run CALL start(); to start the game. Run CALL jump(); to jump.';
