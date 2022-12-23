#!/bin/bash

# Installation
sudo apt update
sudo apt install libaio1 libmecab2 libncurses5 libtinfo5 -y

wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb

sudo mkdir /var/lib/mysql-cluster

echo "
[ndbd default]
# Options affecting ndbd processes on all data nodes:
NoOfReplicas=3	                                # Number of replicas

[ndb_mgmd]
# Management process options:
hostname=ip-172-31-81-1.ec2.internal            # Hostname of the manager
datadir=/var/lib/mysql-cluster 	                # Directory for the log files
NodeId=1

[ndbd]
hostname=ip-172-31-81-2.ec2.internal            # Hostname/IP of the first data node
NodeId=2			                            # Node ID for this data node
datadir=/usr/local/mysql/data	                # Remote directory for the data files

[ndbd]
hostname=ip-172-31-81-3.ec2.internal            # Hostname/IP of the second data node
NodeId=3			                            # Node ID for this data node
datadir=/usr/local/mysql/data	                # Remote directory for the data files

[ndbd]
hostname=ip-172-31-81-4.ec2.internal            # Hostname/IP of the third data node
NodeId=4			                            # Node ID for this data node
datadir=/usr/local/mysql/data	                # Remote directory for the data files

[mysqld]
# SQL node options:
hostname=ip-172-31-81-1.ec2.internal            # In our case the MySQL server/client is on the same Droplet as the cluster manager
NodeId=40
" | tee -a /var/lib/mysql-cluster/config.ini

echo "
[Unit]
Description=MySQL NDB Cluster Management Server
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
" | tee -a /etc/systemd/system/ndb_mgmd.service

sudo systemctl daemon-reload
sudo systemctl enable ndb_mgmd
sudo systemctl start ndb_mgmd

wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster_7.6.6-1ubuntu18.04_amd64.deb-bundle.tar
mkdir install
tar -xvf mysql-cluster_7.6.6-1ubuntu18.04_amd64.deb-bundle.tar -C install/
cd install

sudo dpkg -i mysql-common_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-cluster-community-client_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-client_7.6.6-1ubuntu18.04_amd64.deb

# Gotten from : https://gist.github.com/ziadoz/dc935a0167c68fc23b4f35ee8593125f  (automate password)
sudo debconf-set-selections <<< 'mysql-cluster-community-server_7.6.6 mysql-cluster-community-server/root-pass password TempPass'
sudo debconf-set-selections <<< 'mysql-cluster-community-server_7.6.6 mysql-cluster-community-server/re-root-pass password TempPass'
sudo debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"


sudo dpkg -i mysql-cluster-community-server_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-server_7.6.6-1ubuntu18.04_amd64.deb

echo "
[mysqld]
# Options for mysqld process:
ndbcluster                      # run NDB storage engine

[mysql_cluster]
# Options for NDB Cluster processes:
ndb-connectstring=ip-172-31-81-1.ec2.internal  # location of management server
" | tee -a /etc/mysql/my.cnf

sudo systemctl restart mysql
sudo systemctl enable mysql

# Installation of Sakila
cd ~
wget https://downloads.mysql.com/docs/sakila-db.tar.gz -O /home/ubuntu/sakila-db.tar.gz
tar -xvf /home/ubuntu/sakila-db.tar.gz -C /home/ubuntu/
# Create & Populate the database structure
sudo mysql -u root -pTempPass -e "SOURCE /home/ubuntu/sakila-db/sakila-schema.sql;"
sudo mysql -u root -pTempPass -e "SOURCE /home/ubuntu/sakila-db/sakila-data.sql;"

# Install & Run SysBench
sudo apt install sysbench -y
sudo sysbench oltp_read_write --table-size=50000 --mysql-user=root --mysql-password=TempPass --mysql-db=sakila --mysql_storage_engine=ndbcluster --db-driver=mysql prepare
sudo sysbench oltp_read_write --table-size=50000 --mysql-user=root --mysql-password=TempPass --mysql-db=sakila --mysql_storage_engine=ndbcluster --db-driver=mysql --max-requests=0 --max-time=60 --num-threads=6 run > /home/ubuntu/results.txt
sudo sysbench oltp_read_write --table-size=50000 --mysql-user=root --mysql-password=TempPass --mysql-db=sakila --mysql_storage_engine=ndbcluster --db-driver=mysql cleanup
