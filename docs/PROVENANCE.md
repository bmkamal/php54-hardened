# Provenance: where every input to the build comes from

Every file that goes into the hardened PHP build is listed here with its source and a
checksum, so anyone can fetch the same inputs and check they are identical.

## Inputs

| Input | Source | Check |
| --- | --- | --- |
| PHP source package | https://oss.oracle.com/ol7/SRPMS-updates/php-5.4.16-48.el7.src.rpm (Oracle Linux 7 rebuild of Red Hat's php-5.4.16-48.el7) | SHA-256 `14273a817f15748ec591a0d88288a3828423493f83da8a6fa7a5c962c0dcc60d`, checked automatically by `build/build.sh` |
| Build container image | Docker Hub `oraclelinux:7` | Image digest `sha256:767c93c07b1fa621ae56d1f5f090e8c0dce7eb452e7dda1e74bbe7546504d63f` |
| Build tools and libraries | Oracle Linux 7 yum repositories `ol7_latest` and `ol7_optional_latest`, installed inside the build container | Signed by Oracle; yum checks the signatures |
| Patch | Independent, unofficial open-source port of the official fix to PHP 5.4 (third party), used unchanged and saved here as `patches/php-5.4.16-php2shell.patch` | SHA-256 `cefd460a8a3c73e4ccd42ae478e3cb944e19f713020983e0358878c3a0a7a33e`, 385 lines |
| Official fix the patch is ported from | https://github.com/php/php-src commit `712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`, saved here as `upstream/php-src-712e60f9.patch` | 17 files changed, 240 insertions, 59 deletions. The commit hash itself proves the content |
| Build script | `build/build.sh` in this repo | SHA-256 `de6e10838ba1d6b41166690bcbb475fef3def253d002134ebbffc7c9b6ea55c0` |

## Changes to Red Hat's build recipe

`build/build.sh` makes exactly three edits to Red Hat's `php.spec`, and nothing else:

1. `Release: 48%{?dist}` becomes `Release: 48%{?dist}.hardened.1`, so the packages are labelled and install as an upgrade.
2. `Patch9001: php-5.4.16-php2shell.patch` is added after Red Hat's last patch line (`Patch167`).
3. `%patch9001 -p1 -b .php2shell` is added after `%patch167`, so the patch is applied after all of Red Hat's own patches.

The build log shows these lines (the `grep` step), and shows `Patch #9001` being applied.

## Outputs (filled in after each build)

| Item | Value |
| --- | --- |
| Release | v1.0.0 |
| Build date | |
| Built by | |
| Build log | `build.log` (kept outside Git; attach to the change record) |
| RPM checksums | `releases/v1.0.0/SHA256SUMS` |
| Signing key fingerprint | |
| Test results (stock vs patched) | |
| PHP test suite comparison | |

## How to check this yourself

1. Download the source package from the URL above and run `sha256sum` on it.
2. Run `docker pull oraclelinux:7` and compare the digest it prints.
3. Run `sha256sum` on `patches/php-5.4.16-php2shell.patch` and compare it with the value above.
4. Clone php-src, run `git show 712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`, and compare it with `upstream/php-src-712e60f9.patch`.
5. Follow `docs/CHANGES.md` to match every change in the patch to the official fix.
