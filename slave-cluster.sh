#!/bin/bash

# Installation
sudo apt update
sudo apt install libclass-methodmaker-perl libncurses5 libaio1 libmecab2 -y

# MySQL Cluster Data Node
wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb

# Config for the Data Node
echo "
[mysql_cluster]
# Options for NDB Cluster processes:
ndb-connectstring=ip-172-31-81-1.ec2.internal  # location of cluster manager
" | tee -a /etc/my.cnf

mkdir -p /usr/local/mysql/data

# Service for Data Node Daemon
echo "
[Unit]
Description=MySQL NDB Data Node Daemon
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndbd
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
" | tee -a /etc/systemd/system/ndbd.service

# NDBD service on start
sudo systemctl daemon-reload    # reload systemd’s manager configuration
sudo systemctl enable ndbd      # enable the service we just created so that the data node daemon starts on reboot
sudo systemctl start ndbd       # start the service