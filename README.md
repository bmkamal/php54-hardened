# php54-hardened

Hardened build of Red Hat's PHP 5.4.16 (`php-5.4.16-48.el7`) for RHEL/CentOS 7, with a
port of PHP's official fix for PHP2Shell (CVE-2026-109618, CVE-2026-109619).

PHP and Red Hat have not released a fix for PHP 5.4. This repository builds the standard
RHEL 7 PHP packages from Red Hat's own source with one added patch, and records every
input, change and test so the result can be checked and rebuilt independently.

This is a stopgap until the application moves to a supported PHP version.

## Where to start

| If you want to... | Read |
| --- | --- |
| See every code change, why it was made and how it compares with PHP's official fix | [docs/CHANGES.md](docs/CHANGES.md) |
| Check where every build input comes from, with checksums | [docs/PROVENANCE.md](docs/PROVENANCE.md) |
| Read the patch itself | [patches/php-5.4.16-php2shell.patch](patches/php-5.4.16-php2shell.patch) |
| Compare it with PHP's official 7.4 fix | [upstream/php-src-712e60f9.patch](upstream/php-src-712e60f9.patch) |
| Install on a server | [install/INSTALL.md](install/INSTALL.md) |
| Check a server after installing | [install/verify.sh](install/verify.sh) |

## What's in the repository

| Folder | Contents |
| --- | --- |
| `patches/` | The fix: one patch file changing 10 C source files |
| `upstream/` | PHP's official fix (php-src commit 712e60f9), for side-by-side review |
| `build/` | `build.sh`, which builds the RPM packages inside an Oracle Linux 7 container |
| `docker/` | Two test containers: stock Red Hat PHP and the patched build |
| `tests/` | Test settings and the four test pages used to compare the two containers |
| `install/` | Install runbook and read-only check script for the server |
| `docs/` | Change register and provenance record |
| `releases/` | Checksums of each released build and archive |

Built packages (`out/`) are not stored in Git. Each tagged version records the checksums
of the archive that was built and tested from it.

## Rebuild it yourself

Needs Docker. From the repository folder:

    docker run --rm --platform linux/amd64 -v "$PWD:/repo" oraclelinux:7 bash /repo/build/build.sh 2>&1 | tee build.log

The script downloads Red Hat's PHP source (checked by SHA-256), adds the patch with three
edits to Red Hat's build recipe, and builds the RPMs into `out/rpms`. The build log shows
the patch being applied to exactly 10 files. Rebuilt RPMs contain the same code but are not
byte-for-byte identical to a previous build, because RPMs record their build time.

## Test it yourself

    docker build --platform linux/amd64 -t php54-stock -f docker/stock/Dockerfile .
    docker build --platform linux/amd64 -t php54-patched -f docker/patched/Dockerfile .
    docker run -d --platform linux/amd64 --name php-stock -p 8081:80 php54-stock
    docker run -d --platform linux/amd64 --name php-patched -p 8082:80 php54-patched

Then send the same requests to `http://localhost:8081/test/` (stock) and
`http://localhost:8082/test/` (patched), using the pages in `tests/web/`. The stock build
behaves the old, vulnerable way and the patched build the fixed way.

## Releases

| Tag | Archive | Archive SHA-256 |
| --- | --- | --- |
| `v1.0.0-staging` | `php54-hardened-1.0.0-staging.tar.gz` | `8037dd18e47a015ecb278d78cf3d7e81a7318f94f4ded08448c2de072f5607be` |

## Known gap

PHP's official fix also changes `substring_conf()` in `main/rfc1867.c` from `int` to
`size_t`. This patch does not include it (N01 in the change register). The risk is low,
because `post_max_size` limits request size; it is planned for a later release.
