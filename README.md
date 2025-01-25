[![wakatime](https://wakatime.com/badge/user/9fe7f760-f7ae-4acf-9bf7-44634e56b55a/project/d59d4499-b38c-4a54-bc55-e32a8e1b603a.svg)](https://wakatime.com/badge/user/9fe7f760-f7ae-4acf-9bf7-44634e56b55a/project/d59d4499-b38c-4a54-bc55-e32a8e1b603a)

# Games in SQL

Script to run postgres in docker:

```bash
docker run --name some-postgres -p 5432:5432 -e POSTGRES_PASSWORD=admin -d postgres
```

Some games will run in any postgres client, some will require `psql` terminal.

### Index

- [2048](#2048)
- [Flappybird](#flappybird)
- [Wordle](#wordle)

### Input tool

In tools folder you can find `input.bash` script that is used to send input to database.
It interacts with made by me `get_key()` function that will handle keyborad input.

For now it works with flappybird game, replacing second terminal used to send jump command.
In flappybird game you can use `arrow up` to jump.

To use `input.bash` run it as it was `psql` command, for example:

```bash
./tools/inputs.bash -U postgres -p 5432 -h 127.0.0.1
```

### 2024

_Will run in any postgres client_

2048 game written in sql, because I was bored on weekend.

Run given sql script (`2048.sql`) in yor postgres database. Instruction how to play will be shown after import or you can read them here:

To start game run `SELECT * FROM init();`

To move run:

- up: `SELECT * FROM up();`
- down: `SELECT * FROM down();`
- left: `SELECT * FROM left();`
- right: `SELECT * FROM right();`

### Flappybird

_Requires psql client_

Flappybird in sql. To run you need to run from `psql` termianl.

1. Launch psql: `psql -U postgres -p 5432 -h 127.0.0.1`
2. Import `flappybird.sql` (eq. `\i flappybird.sql`)
3. Run `CALL start()`
4. From other terminal or some other postgres client run query `CALL jump()` to jump.

### Wordle

_Requires psql client_

Wordle game in sql. To run you need to run from `psql` termianl.

1. Launch psql: `psql -U postgres -p 5432 -h 127.0.0.1`
2. Import `wordle.sql` (eq. `\i wordle.sql`)
3. Import word list from `wordle_words.sql` (eq. `\i wordle_words.sql`)
4. Run `CALL play()` and then `CALL play('word')` to guess word.
5. To reset just run `CALL play()` again.

### Cool sources and resources I used

- [Posts by Greg Sabino Mullane | PostgreSQL Blog | Crunchy Data](https://www.crunchydata.com/blog/author/greg-sabino-mullane)
  - [Fun with PostgreSQL Puzzles: Moving Objects...](https://www.crunchydata.com/blog/fun-with-postgresql-puzzles-moving-objects-with-arrays-sequences-and-aggregates)
