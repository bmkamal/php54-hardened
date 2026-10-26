#!/bin/bash
# Builds patched PHP 5.4.16 RPMs for EL7. Run inside an oraclelinux:7 container.
set -euo pipefail

SRPM_URL=https://oss.oracle.com/ol7/SRPMS-updates/php-5.4.16-48.el7.src.rpm
SRPM_SHA256=14273a817f15748ec591a0d88288a3828423493f83da8a6fa7a5c962c0dcc60d

echo "== Installing build tools"
yum -y -q install yum-utils rpm-build make gcc gcc-c++ redhat-rpm-config tar patch bzip2 cpio curl
yum-config-manager -q --enable ol7_optional_latest >/dev/null

echo "== Downloading and checking the PHP source package"
cd /root
curl -fsSL -o php.src.rpm "$SRPM_URL"
echo "$SRPM_SHA256  php.src.rpm" | sha256sum -c -
rpm -i php.src.rpm

echo "== Adding our patch to the build recipe"
cp /repo/patches/php-5.4.16-php2shell.patch /root/rpmbuild/SOURCES/
cd /root/rpmbuild/SPECS
sed -i 's/^Release: 48%{?dist}$/Release: 48%{?dist}.hardened.1/' php.spec
sed -i '/^Patch167: /a Patch9001: php-5.4.16-php2shell.patch' php.spec
sed -i '/^%patch167 /a %patch9001 -p1 -b .php2shell' php.spec
grep -n 'hardened\|9001' php.spec

echo "== Installing PHP's build dependencies"
yum-builddep -y -q php.spec

echo "== Building (this takes a while)"
rpmbuild -ba --nocheck --define 'dist .el7' --define "_smp_mflags -j$(nproc)" php.spec

mkdir -p /repo/out/rpms
cp /root/rpmbuild/RPMS/x86_64/*.rpm /repo/out/rpms/
(cd /repo/out/rpms && sha256sum -- *.rpm > SHA256SUMS)
echo "== Done. RPMs are in out/rpms"
ls /repo/out/rpms
