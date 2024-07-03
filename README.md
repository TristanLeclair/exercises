# Postgres exercises

Practice postgres problems taken from [pgexercises.com](https://pgexercises.com/)

## Create and reset DB

### Locally

run `./reset_db.sh` to reset the database if running postgres locally

### With docker-compose

`docker compose down -v` will delete the volume, and when you restart the container, it'll rerun the initialization script [clubdata.sql](./init/clubdata.sql) which is automatically mounted into the container.
