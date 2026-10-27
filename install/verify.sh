#!/bin/bash
# Checks the hardened PHP build is installed and running. Read-only.
fail=0
pass() { echo "PASS  $1"; }
bad()  { echo "FAIL  $1"; fail=1; }
warn() { echo "WARN  $1"; }

old=$(rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE} %{SOURCERPM}\n' 'php*' \
      | awk '$2 ~ /^php-5\.4\.16-/ && $1 !~ /hardened/ {print $1}')
[ -z "$old" ] && pass "all PHP packages are the hardened build" || bad "not hardened: $old"

for f in /usr/lib64/httpd/modules/libphp5.so /usr/sbin/php-fpm; do
  [ -e "$f" ] || continue
  rpm -qf "$f" | grep -q hardened && pass "$f is from the hardened build" || bad "$f is not from the hardened build"
done

php -i 2>/dev/null | grep -q '^max_multipart_body_parts' \
  && pass "patched code present (max_multipart_body_parts)" \
  || bad "max_multipart_body_parts setting missing: patched code not loaded"

up=$(php -r 'echo ini_get("session.upload_progress.enabled") ? "On" : "Off";' 2>/dev/null)
[ "$up" = "Off" ] && pass "session.upload_progress.enabled is Off" \
  || warn "session.upload_progress.enabled is On (the patch still blocks it; set Off as an extra layer)"

if command -v lsof >/dev/null; then
  stale=$(lsof -n 2>/dev/null | grep -E 'php.*\(deleted\)')
  [ -z "$stale" ] && pass "no process is running old PHP files" || bad "restart needed: processes still use replaced PHP files"
else
  warn "lsof not installed, skipped the stale process check"
fi

[ "$fail" -eq 0 ] && echo "RESULT: OK" || echo "RESULT: PROBLEMS FOUND"
exit "$fail"
