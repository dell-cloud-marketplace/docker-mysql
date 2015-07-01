#docker-mysql

This is a base Docker image to run a [MySQL](http://www.mysql.com/) database server.

## Components
The software stack comprises the following component details:

Name       | Version    | Description
-----------|------------|------------------------------
Ubuntu     | Trusty     | Operating system
MySQL      | 5.6        | Database

## Usage

### Start the Container
To start your container with:

* A named container ("mysql")
* Host port 3306 mapped to container port 3306 (default MySQL port)

Do:
```no-highlight
sudo docker run -d -p 3306:3306 --name mysql dell/mysql
```

A new admin user, with all privileges, will be created in MySQL with a random password. To get the password, check the container logs (```sudo docker logs mysql```). You will see output like the following:


```no-highlight
========================================================================
You can now connect to this MySQL Server using:

    mysql -uadmin -pcPeW8P7qr0Cs -h<host> -P<port>

Please remember to change the above password as soon as possible!
MySQL user 'root' has no password but only allows local connections
========================================================================
```

In this case, `cPeW8P7qr0Cs` is the password allocated to the `admin` user.

Remember that the `root` user has no password but it's only accessible from within the container.

You can then connect to MySQL using:

```no-highlight
mysql -uadmin -pcPeW8P7qr0Cs -h127.0.0.1 -P3306
```

### Advanced Example 1
* A named container ("mysql")
* A host port 3306 mapped to container port 3306 (default MySQL port)
- A specific MySQL password for user **admin**. A preset password can be defined instead of a randomly generated one, this is done by setting the environment variable `MYSQL_PASS` to your specific password when running the container.

```no-highlight
sudo docker run -d -p 3306:3306 -e MYSQL_PASS="mypass" --name mysql dell/mysql
```

You can then connect to MySQL using:

```no-highlight
mysql -uadmin -pmypass -h127.0.0.1 -P3306
```

The admin username can also be set via the `MYSQL_USER` environment variable.

### Advanced Example 2

Start your container with:
* A named container ("mysql")
* A host port 3306 mapped to container port 3306 (default MySQL port)
- Two data volumes (which will survive a restart or recreation of the container). The MySQL data is available in **/var/lib/mysql** on the host. The configuration files are available in **/etc/mysql** on the host.
- A specific MySQL password for user **admin**. A preset password can be defined instead of a randomly generated one, this is done by setting the environment variable `MYSQL_PASS` to your specific password when running the container.

```no-highlight
sudo docker run -d \
	-v /etc/mysql:/etc/mysql \
	-v /var/lib/mysql:/var/lib/mysql \
	-p 3306:3306 \
	-e MYSQL_PASS="mypass" \
	--name mysql dell/mysql
```

You can then connect to MySQL using:

```no-highlight
mysql -uadmin -pmypass -h127.0.0.1 -P3306
```
      
## Replication - Master/Slave

In order to use MySQL replication, start two containers, respectively master and slave with the following parameters: 

Start the master container with:
* A named container ("master")
* A host port 3306 mapped to container port 3306
* Replication in master-mode enabled by setting `REPLICATION_MASTER` to `true`. 
- Each slave must connect to the master using a MySQL user name and password. To do so, a MySQL user granted to perform replication is created on the master that the slave can use to connect. Preset login and password can be defined instead of the default ones by setting `REPLICATION_USER` and `REPLICATION_PASS`. The default value is `replica:replica`. 

```no-highlight
sudo docker run -d \
	-e REPLICATION_MASTER=true \
	-e REPLICATION_USER="rep_user" \
	-e REPLICATION_PASS="mypass" \
	-e MYSQL_PASS="mypass" \
	-p 3306:3306 \
	--name master \
	dell/mysql
```

Start the slave container with:
* A named container ("slave")
* A host port 3307 mapped to container port 3306
* Replication in slave-mode enabled by setting `REPLICATION_SLAVE` to `true`. 
* A link to the master container with the **mysql** alias 

```no-highlight
sudo docker run -d \
	-e REPLICATION_SLAVE=true \
	-p 3307:3306 \
	--link master:mysql \
	-e MYSQL_PASS="mypass" \
	--name slave \
	dell/mysql
```

You can then connect to your MySQL master and slave nodes respectively on port 3306 and 3307.

### Test the Replication

#### Check MySQL Master Status

Connect to your MySQL master node on port **3306** using:

```no-highlight
mysql -uadmin -pmypass -h127.0.0.1 -P3306
```

and run:

```no-highlight
SHOW MASTER STATUS\G
```
You will see output like the following:

```no-highlight
mysql> SHOW MASTER STATUS\G
*************************** 1. row ***************************
             File: master-bin.000002
         Position: 1307
     Binlog_Do_DB: test
 Binlog_Ignore_DB: manual, mysql
Executed_Gtid_Set: 3E11FA47-71CA-11E1-9E33-C80AA9429562:1-5
1 row in set (0.00 sec)
```

#### Create a New Database 

On the master, create a new database to test the replication:

```no-highlight
mysql> CREATE DATABASE test_replication_db;
```

#### Check MySQL Node Status

Connect to your MySQL slave node on port **3307** using:

```no-highlight
mysql -uadmin -pmypass -h127.0.0.1 -P3307
```

and run:


```no-highlight
SHOW SLAVE STATUS\G
```

You will see output like the following:

```no-highlight
mysql>  SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.17.5.69
                  Master_User: rep_user
                  Master_Port: 3306
                               ...
                               ..
                               .
```

#### Check the Database Replication

List databases on the slave :

```no-highlight
mysql>  SHOW DATABASES;
```
Check that the database **test_replication_db** created on the master node has been correctly replicated
 
## Reference

### Environmental Variables

Variable           | Default   | Description
-------------------|-----------|-----------------------------------------------------------
MYSQL_USER         | admin     | The administrator user name
MYSQL_PASS         | *random*  | Password for the MySQL administrator user
REPLICATION_MASTER | \*\*False\*\* | Override the default to run MySQL as a replication master
REPLICATION_SLAVE  | \*\*False\*\* | Override the default to run MySQL as a replication slave
REPLICATION_USER   | replica   | The replication user name
REPLICATION_PASS   | replica   | The replication password

### Image Details

Based on [tutum/mysql](https://github.com/tutumcloud/tutum-docker-mysql)

Pre-built Image | [https://registry.hub.docker.com/u/dell/mysql](https://registry.hub.docker.com/u/dell/mysql) 
