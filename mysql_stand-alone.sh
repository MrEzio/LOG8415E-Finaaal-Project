#!/bin/bash

# Installation of MySQL
sudo apt update
sudo apt install mysql-server -y

# Installation of Sakila
wget https://downloads.mysql.com/docs/sakila-db.tar.gz -O /home/ubuntu/sakila-db.tar.gz
tar -xvf /home/ubuntu/sakila-db.tar.gz -C /home/ubuntu/
# Create & Populate the database structure
sudo mysql -u root -e "SOURCE /home/ubuntu/sakila-db/sakila-schema.sql;"
sudo mysql -u root -e "SOURCE /home/ubuntu/sakila-db/sakila-data.sql;"

# Install & Run SysBench
sudo apt install sysbench -y
sudo sysbench oltp_read_write --table-size=50000 --mysql-user=root --mysql-db=sakila --db-driver=mysql prepare
sudo sysbench oltp_read_write --table-size=50000 --mysql-user=root --mysql-db=sakila --db-driver=mysql --max-requests=0 --max-time=60 --num-threads=6 run > /home/ubuntu/results.txt
sudo sysbench oltp_read_write --table-size=50000 --mysql-user=root --mysql-db=sakila --db-driver=mysql cleanup