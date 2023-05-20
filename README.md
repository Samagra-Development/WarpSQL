<p align="center"><img align="center" width="280" height="280" src="./icon.jpeg"/></p>
<h1 align="center">WarpSQL</h3>
<hr>
Opinionated extensions to Postgres packaged as a single docker deployment. Why install 10 DBs when you can can have everthing  at once (maybe not everything).

Certified as Indie Hacker's best friend!!!

### Test on GitPod
[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/ChakshuGautam/postgres-tsdb-vector-docker)

### Current and future supported extensions

- [x] [PgVector](https://github.com/pgvector/pgvector)
- [x] [TimescaleDB](https://github.com/timescale/timescaledb)
- [x] [Citus](https://www.citusdata.com/)
- [x] [PostGIS](https://postgis.net)
- [ ] [ZomboDB](https://github.com/zombodb/zombodb)
- [ ] [PLV8](https://github.com/plv8/plv8)
- [ ] [Pg Repack](https://github.com/reorg/pg_repack)

Bootstrapped from [TimescaleDB](https://github.com/timescale/timescaledb-docker)

### Usage with Compose

```yaml
version: '3.6'
services:
  warpsql:
    container_name: warpsql
    image: samagragovernance/postgres:latest-pg15
    restart: always
    ports:
      - "5432:5432"
    volumes:
      - ./pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: warpSQLUser
      POSTGRES_PASSWORD: warpSQLPass
```

## Development with GitHub Codespaces

You can use GitHub Codespaces to develop this project in the cloud.

1. Click on the "Code" button.
2. Select "Open with Codespaces" from the dropdown menu.
3. Choose the appropriate Codespace configuration.
4. Wait for the environment to be provisioned.
5. Once the environment is ready, you can start working on the project.
6. Install the project dependencies by running the following command in the terminal:

   ```bash
   pip install -r requirements.txt
