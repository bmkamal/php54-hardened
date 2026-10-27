# Install php54-hardened on a RHEL/CentOS 7 VM

Hardened build of Red Hat's php-5.4.16-48.el7 with a fix for PHP2Shell
(CVE-2026-109618, CVE-2026-109619). Restarting Apache causes a short outage, so do
this in an agreed change window, on a staging VM before production. Run every
command as root (sudo -i).

## 1. Check this is the right VM

    cat /etc/redhat-release     # must say release 7.x
    rpm -q php-common           # must be php-common-5.4.16-48.el7.x86_64

If either is different, stop and contact the build owner.

## 2. Unpack and check the release files

Copy the archive to /root on the VM, then:

    cd /root
    sha256sum php54-hardened-*.tar.gz        # must match the checksum you were sent separately
    tar -xzf php54-hardened-*.tar.gz
    cd /root/php54-hardened
    sha256sum -c SHA256SUMS                  # every line must say OK

Signed releases only (the archive contains RPM-GPG-KEY-php54-hardened):

    rpm --import RPM-GPG-KEY-php54-hardened
    rpm -K *.rpm                             # every line must include "pgp" and end "OK"

Staging builds may be unsigned. Never install an unsigned build on production.

## 3. Back up

    mkdir -p /root/php-backup
    rpm -qa 'php*' | sort > /root/php-backup/packages-before.txt
    cp -a /etc/php.ini /etc/php.d /root/php-backup/

Make sure the current Red Hat PHP packages can be reinstalled for rollback: either
the VM's normal repository (for example Satellite) is reachable, or copies are in
/root/php-rollback (yumdownloader --destdir /root/php-rollback <package names>).

## 4. Work out which packages to install

Run steps 4 and 5 in the same terminal.

    cd /root/php54-hardened
    FILES=""
    for p in $(rpm -qa --qf '%{NAME} %{SOURCERPM}\n' 'php*' | awk '$2 ~ /^php-5\.4\.16-/ {print $1}'); do
      f=$p-5.4.16-48.el7.hardened.1.x86_64.rpm
      if [ -f "$f" ]; then FILES="$FILES $f"; else echo "MISSING: $f"; fi
    done
    echo "Will install:$FILES"

If any MISSING line appears, stop.

## 5. Install, configure, restart

    yum -y --disablerepo='*' localinstall $FILES
    echo 'session.upload_progress.enabled = Off' > /etc/php.d/zz-php2shell.ini
    systemctl restart httpd
    systemctl is-active --quiet php-fpm && systemctl restart php-fpm

## 6. Verify

    bash verify.sh

Every check must say PASS and the last line must say RESULT: OK. Then run the
application owner's smoke test (log in, browse, create content, upload a file).
Send the verify.sh output and /root/php-backup/packages-before.txt back to the
build owner.

## Rollback

From the normal repository:

    yum -y downgrade $(rpm -qa --qf '%{NAME} %{SOURCERPM}\n' 'php*' | awk '$2 ~ /^php-5\.4\.16-/ {print $1}')

Or, without repository access:

    yum -y --disablerepo='*' downgrade /root/php-rollback/*.rpm

Then:

    systemctl restart httpd
    rpm -q php                  # must no longer contain "hardened"
