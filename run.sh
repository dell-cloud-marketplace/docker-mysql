#!/bin/bash

DATA_DIR="/var/lib/mysql"
CONFIG_DIR="/etc/mysql"
TMP_CONFIG_DIR="/tmp/etc/mysql"
CONF_FILE="/etc/mysql/conf.d/my.cnf"

# Test if CONFIG_DIR has content.
if [ ! "$(ls -A $CONFIG_DIR)" ]; then
    # Copy the configuration that we generated within the container to the
    # empty CONFIG_DIR.
    cp -r $TMP_CONFIG_DIR/* $CONFIG_DIR
fi

# Change ownership of MySQL volumes
chown -R mysql:mysql $DATA_DIR $CONFIG_DIR
 
StartMySQL ()
{
    /usr/bin/mysqld_safe > /dev/null 2>&1 &
    RET=1
    while [[ RET -ne 0 ]]; do
        echo "=> Waiting for confirmation of MySQL service startup"
        sleep 5
        mysql -uroot -e "status" > /dev/null 2>&1
        RET=$?
    done
}

if [ ${REPLICATION_MASTER} == "**False**" ]; then
    unset REPLICATION_MASTER
fi

if [ ${REPLICATION_SLAVE} == "**False**" ]; then
    unset REPLICATION_SLAVE
fi

# Install MySQL and create the admin user
if [[ ! -d $DATA_DIR/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $DATA_DIR"
    echo "=> Installing MySQL ..."
    if [ ! -f /usr/share/mysql/my-default.cnf ] ; then
        cp /etc/mysql/my.cnf /usr/share/mysql/my-default.cnf
    fi 
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"  
    echo "=> Creating admin user ..."
    /create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi


# Set MySQL REPLICATION - MASTER
if [ -n "${REPLICATION_MASTER}" ]; then 
    echo "=> Configuring MySQL replication as master ..."
    if [ ! -f /replication_configured ]; then
        RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
        echo "=> Writting configuration file '${CONF_FILE}' with server-id=${RAND}"
        sed -i "s/^#server-id.*/server-id = ${RAND}/" ${CONF_FILE}
        sed -i "s/^#log-bin.*/log-bin = mysql-bin/" ${CONF_FILE}
        echo "=> Starting MySQL ..."
        StartMySQL
        echo "=> Creating a log user ${REPLICATION_USER}:${REPLICATION_PASS}"
        mysql -uroot -e "CREATE USER '${REPLICATION_USER}'@'%' IDENTIFIED BY '${REPLICATION_PASS}'"
        mysql -uroot -e "GRANT REPLICATION SLAVE ON *.* TO '${REPLICATION_USER}'@'%'"
        echo "=> Done!"
        mysqladmin -uroot shutdown
        touch /replication_configured
    else
        echo "=> MySQL replication master already configured, skip"
    fi
fi

# Set MySQL REPLICATION - SLAVE
if [ -n "${REPLICATION_SLAVE}" ]; then 
    echo "=> Configuring MySQL replication as slave ..."
    if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ] && [ -n "${MYSQL_PORT_3306_TCP_PORT}" ]; then
        if [ ! -f /replication_configured ]; then
            RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
            echo "=> Writting configuration file '${CONF_FILE}' with server-id=${RAND}"
            sed -i "s/^#server-id.*/server-id = ${RAND}/" ${CONF_FILE}
            sed -i "s/^#log-bin.*/log-bin = mysql-bin/" ${CONF_FILE}
            echo "=> Starting MySQL ..."
            StartMySQL
            echo "=> Setting master connection info on slave"
            mysql -uroot -e "CHANGE MASTER TO MASTER_HOST='${MYSQL_PORT_3306_TCP_ADDR}',MASTER_USER='${MYSQL_ENV_REPLICATION_USER}',MASTER_PASSWORD='${MYSQL_ENV_REPLICATION_PASS}',MASTER_PORT=${MYSQL_PORT_3306_TCP_PORT}, MASTER_CONNECT_RETRY=30"
            echo "=> Done!"
            mysqladmin -uroot shutdown
            touch /replication_configured
        else
            echo "=> MySQL replication slave already configured, skip"
        fi
    else 
        echo "=> Cannot configure slave, please link it to another MySQL container with alias as 'mysql'"
        exit 1
    fi
fi

exec supervisord -n
