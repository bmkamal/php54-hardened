FROM oraclelinux:7
RUN yum -y install httpd php && yum clean all
COPY tests/php-test.ini /etc/php.d/zz-test.ini
COPY tests/web/ /var/www/html/test/
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
