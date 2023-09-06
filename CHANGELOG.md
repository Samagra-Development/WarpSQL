# Changelog

This file contains all changelogs for WarpSQL releases

## v1.1

### Added
-  Docker based deployments over EC2 (Infra - Terraform, Configuration - Ansible) with disaster recovery support ([#105](https://github.com/Samagra-Development/WarpSQL/pull/105))
- Add Image analysis to Github Workflow ([#91](https://github.com/Samagra-Development/WarpSQL/pull/91))
- Static website for README.md made ([#95](https://github.com/Samagra-Development/WarpSQL/pull/95))
- Add packer template and updated workflow ([#89](https://github.com/Samagra-Development/WarpSQL/pull/89))
- Added pgwatch2 service ([#78](https://github.com/Samagra-Development/WarpSQL/pull/78))
#### Extensions
- add pgvector to the bitnami image ([#84](https://github.com/Samagra-Development/WarpSQL/pull/84))
- pgautofailover ([#40](https://github.com/Samagra-Development/WarpSQL/pull/40))
- pg_repack ([#35](https://github.com/Samagra-Development/WarpSQL/pull/35))
- zombodb ([#33](https://github.com/Samagra-Development/WarpSQL/pull/33))
- postgis ([#19](https://github.com/Samagra-Development/WarpSQL/pull/19))


### Fixed
- Reduce the size of bitnami Image ([#96](https://github.com/Samagra-Development/WarpSQL/pull/96))
- add docker cache to github action ([#53](https://github.com/Samagra-Development/WarpSQL/pull/53))