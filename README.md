# LOG8415E-Finaaal-Project
Github for final project of LOG8415E

# Steps in the beginning
- Make sure you have AWS CLI installed. In your credentials make sure your variables are updated.
- Make sure to have python3, boto3, pymysql sshtunnel.
- Make sure to take in note your ```SUBNET_ID``` that has the ```CIDR (172.31.80.0/20)```. In proxy.py & mysql_cluster.py, you will need to write it in the command.
- Make sure to create a Key Pair and have it somewhere in your local. In my case I created "```final.pem```" & put it in Desktop. 

# Standalone benchmark
- To benchmark the standalone MySQL, just run : ```python mysql_stand-alone.py```.
- Once you see the message "Results are now available in the file results.txt!", SSH into the instance ```MySQL_stand-alone``` and make sure to be in ```/home/ubuntu/results.txt```. (txt in Github to see results).

# MySQL Cluster benchmark
- To benchmark the MySQL Cluster, just run : ```python mysql_cluster.py SUBNET_ID```.
- Once you see the message "Results are now available in the file results.txt!", SSH into the instance ```Master``` and make sure to be in ```/home/ubuntu/results.txt```. (txt in Github to see results).

# Proxy Cloud Pattern
- If it wasn't done already, do the step MySQL Cluster benchmark (one above) first, which will create 4 instances -> 1 Master and 3 Slaves.
- After, to create the Proxy instance run : ```python proxy.py SUBNET_ID```.
- SSH into the Proxy instance and make sure to be in /home/ubuntu : ```git clone https://github.com/MrEzio/LOG8415E-Finaaal-Project.git```. 

- Once the Proxy instance is created & the cloning part is done, copy the SSH key used to create the Proxy instance ("```final.pem```") from your local machine to the Proxy instance by doing (in this case I'm already in the folder containing the final.pem key): 
```scp -i final.pem final.pem ubuntu@<PUBLIC_IP_OF_PROXY_INSTANCE>:/home/ubuntu/LOG8415E-Finaaal-Project/final2.pem```. 
- After this, SSH into the Proxy Instance if you're not already in it, cd into ```LOG8415E-Finaaal-Project``` and do : ```python3 main.py "query_sql"```.
- One example to do would be : ```python3 main.py "SELECT * FROM actor"```.
