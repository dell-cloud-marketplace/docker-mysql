FROM ubuntu:trusty
MAINTAINER Dell Cloud Market Place <Cloud_Marketplace@dell.com>

# Update packages
RUN apt-get update

# Set the environment variable for package install
ENV DEBIAN_FRONTEND noninteractive

# Install MySQL 
RUN apt-get -y install \
  mysql-server-5.6 \
  pwgen \ 
  supervisor && \
  rm -rf /var/lib/apt/lists/*

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL configuration
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Copy MySQL configuration directory in case an empty volume is specified.
RUN mkdir -p /tmp/etc/mysql/ && \
    cp -R /etc/mysql/* /tmp/etc/mysql/ 

# Add MySQL scripts
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
ADD import_sql.sh /import_sql.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Exposed ENVIRONMENT VARIABLES
ENV MYSQL_USER admin
ENV MYSQL_PASS ""
ENV REPLICATION_MASTER **False**
ENV REPLICATION_SLAVE **False**
ENV REPLICATION_USER replica
ENV REPLICATION_PASS replica

# Add volumes to allow backup of configuration and databases
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

# Expose MySQL port
EXPOSE 3306
CMD ["/run.sh"]
