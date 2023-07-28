<p align="center"><img align="center" width="280" height="280" src="./icon.jpeg"/></p>
<h1 align="center">WarpSQL</h3>
Opinionated extensions to Postgres packaged as a single docker deployment. Why install 10 DBs when you can have everything at once (maybe not everything).

Certified as Indie Hacker's best friend!!!

### Current and future supported extensions

- [x] [PgVector](https://github.com/pgvector/pgvector)
- [x] [TimescaleDB](https://github.com/timescale/timescaledb)
- [x] [Citus](https://www.citusdata.com/)
- [x] [PostGIS](https://postgis.net)
- [x] [ZomboDB](https://github.com/zombodb/zombodb)
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

WarpSQL is a powerful solution that provides opinionated extensions to Postgres, conveniently packaged as a single Docker deployment. It eliminates the need to install multiple separate databases by offering a comprehensive set of features in one place (although not everything, as some features might not be included).

By utilizing WarpSQL, you can benefit from the following:

- *Simplified setup*: With WarpSQL, you can have all the necessary extensions for your Postgres database in one go, saving you time and effort.
- *Seamless integration*: WarpSQL includes popular extensions like PgVector, TimescaleDB, Citus, and PostGIS, allowing you to leverage their functionality seamlessly.
- *Enhanced performance*: The included extensions are carefully selected to optimize database performance, enabling you to work efficiently with large datasets.
- *Extensibility*: While WarpSQL already supports a range of extensions, it aims to expand its offerings to include even more powerful tools in the future, such as ZomboDB, PLV8, and Pg Repack.
Get started with WarpSQL today and experience the convenience of a comprehensive Postgres solution.

## PostgreSQL Image Packer Template

This repository contains a Packer template for building the WarpSQL image with multiple sources and provisioners. The template supports building images based on both the Alpine and Bitnami PostgreSQL images.

#### Prerequisites

Before using this Packer template, ensure that you have the following prerequisites installed:

- [Packer](https://www.packer.io/) 
- [Docker](https://www.docker.com/) (for building Docker images)
- AWS 

### Usage

To build the WarpSQL image using the Packer template, follow these steps:

1. Clone this repository and navigate to the packer directory:

   ```shell
    git clone https://github.com/Samagra-Development/WarpSQL.git
    cd WarpSQL/packer
    ```
2. Build the image:

   ```shell
    packer build -only=warpsql.<platform>.alpine warpsql.pkr.hcl
    ```

  By default, all supported [extensions](#list-of-supported-extensions) are installed. If you want to install specific extensions, you can provide the `extensions` variable:
  
  ```shell
  packer build -var extensions='pg_repack,hll'  -only warpsql.docker.alpine warpsql.pkr.hcl  
  ```

  Note that currently only the `Docker` and `AWS` platform has been added to the template.

You can further customize the image repository and tags of `docker` images by providing values for the `image_repository` and `image_tags` variables using the `-var` option. Here's an example command:
```shell
packer build -var="image_repository=your_value" -var="image_tags=[tag1,tag2]" warpsql.pkr.hcl
```

### List of supported extensions
|Extension       | Identifier       |
|----------------|------------------|
|[PgVector](https://github.com/pgvector/pgvector)        | `pgvector`       |
|[TimescaleDB](https://github.com/timescale/timescaledb)     | `timescaledb`    |
|[Citus](https://github.com/citusdata/citus)           | `citus`          |
|[PostGIS](https://github.com/postgis/postgis)         | `postgis`        |
|[ZomboDB](https://github.com/zombodb/zombodb)         | `zombodb`        |
|[PgRepack](https://github.com/reorg/pg_repack)        | `pg_repack`      |
|[PG Auto Failover](https://github.com/hapostgres/pg_auto_failover)| `pgautofailover` |
|[HyperLogLog](https://github.com/citusdata/postgresql-hll)     | `hll`            |
## Contribution

You can contribute to the development of WarpSQL using both Gitpod and Codespaces. Follow the steps below to set up your development environment and make contributions:

### Gitpod

Click the "Open in Gitpod" button above or use the following link:[Open in Gitpod](https://gitpod.io/new/#https://github.com/ChakshuGautam/postgres-tsdb-vector-docker)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/ChakshuGautam/postgres-tsdb-vector-docker)

- Wait for the Gitpod environment to be created and initialized.
- Once the environment is ready, you can start working on the project.
- Make your desired changes or additions.
- Test your changes and ensure they meet the project's guidelines.
- Commit and push your changes to your forked repository.
- Create a pull request from your forked repository to the main WarpSQL repository.

### GitHub Codespaces

You can use GitHub Codespaces to develop this project in the cloud.

[![GitHub Codespaces](https://img.shields.io/badge/GitHub-Codespaces-blue?logo=github)](https://github.com/features/codespaces)

- Click on the "Code" button.
- Select "Open with Codespaces" from the dropdown menu.
- Choose the appropriate Codespace configuration.
- Wait for the environment to be provisioned.

Once the environment is ready, you can start working on the project.

- Make your desired changes or additions.
- Test your changes and ensure they meet the project's guidelines.
- Commit and push your changes to your forked repository.
- Create a pull request from your forked repository to the main WarpSQL repository.
- We welcome contributions from the community and appreciate your support in improving WarpSQL!

### Ensure CI passes ![](https://img.shields.io/badge/CI-Passing-brightgreen)

Before merging any contributions or changes, it's essential to ensure that the continuous integration (CI) tests pass successfully. CI helps maintain code quality standards and prevents the introduction of regressions. To ensure a smooth integration process, follow these steps:

- Make your desired changes or additions to the codebase.
- Run the relevant tests locally to verify that your changes are functioning as expected.
- Push your changes to the branch you're working on.
- The CI system will automatically run tests and checks on your code.
- Monitor the CI build status to ensure that all tests pass successfully.
- If the CI build fails, review the error messages and make the necessary fixes.
- Repeat steps 3-6 until the CI build passes successfully.
- Once the CI build is successful, you can proceed with merging your changes into the main WarpSQL repository.

## Maintainers

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><img src="https://avatars.githubusercontent.com/u/64846852?v=4?s=100" width="100px;" alt="Jayanth Kumar"/><br /><sub><b>Jayanth Kumar</b></sub></a><br /><a href="https://github.com/all-contributors/all-contributors/commits?author=jayanth-kumar-morem" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
