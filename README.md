[![wakatime](https://wakatime.com/badge/user/9fe7f760-f7ae-4acf-9bf7-44634e56b55a/project/d59d4499-b38c-4a54-bc55-e32a8e1b603a.svg)](https://wakatime.com/badge/user/9fe7f760-f7ae-4acf-9bf7-44634e56b55a/project/d59d4499-b38c-4a54-bc55-e32a8e1b603a)

# SQL 2048

2048 game written in sql, because I was bored on weekend.

Script to run postgres in docker:

```bash
docker run --name some-postgres -p 5432:5432 -e POSTGRES_PASSWORD=admin -d postgres
```

### How to play

Run given sql script (`2048.sql`) in yor postgres database. Instruction how to play will be shown after import or you can read them here:

To start game run `SELECT * FROM init();`

To move run:

- up: `SELECT * FROM up();`
- down: `SELECT * FROM down();`
- left: `SELECT * FROM left();`
- right: `SELECT * FROM right();`
