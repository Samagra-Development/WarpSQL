# Version Policy

WarpSQL adopts [Semantic Versioning(SemVer)](https://semver.org/) using the `MAJOR.MINOR.PATCH` format.
For a summary of changes in the WarpSQL refer to the [CHANGELOG](../CHANGELOG.md).

## WarpSQL versions

### MAJOR Version (v1.x.x):

when backward incompatible changes are introduced.
Examples:

- Increment an extension to `MAJOR` versions
- Features causing backward incompatibility

### MINOR Version (vx.1.x):

when new features and extensions are added, but are backward compatible.
Examples:

- Increment an extension to `MINOR`/`PATCH` versions
- Addition of an extension
- Upgrades maintaining backward compatibility

### PATCH Version (vx.x.1):

when backward compatible bug fixes are added.

### PRE-RELEASE (vx.x.x-alpha.2)
This releases might introduce breaking changes on any update. This release carries no stability guarantees.

The pre-release progression follows the sequence:

- Alpha: `-alpha`
- Beta: `-beta`
- Release Candidate: `-rc`

## WarpSQL Docker images 

The WarpSQL images tags follow a consistent naming convention,
deliberately excluding the use of a `latest` tag. This omission is intentional to prevent accidental upgrades in dependencies and PostgreSQL versions.

### Alpine Images
The default base distribution for WarpSQL is Alpine. The tags follow this format:
```html
<warpsql_version>-pg<postgres_version>
<warpsql_version>-pg<postgres_version>-alpine
```
### Bitnami Images

```html    
<warpsql_version>-pg<postgres_version>-bitnami
```

### Examples
- An Alpine image with `warpsql_version=1.2.1-alpha` and PostgreSQL 15 is represented by the tag `1.2.1-alpha-pg15-alpine`.
