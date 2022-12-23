import sys
import pymysql
from sshtunnel import SSHTunnelForwarder

def direct_hit_strategy(query):
    with SSHTunnelForwarder(
        'ip-172-31-81-1.ec2.internal',
        ssh_username="ubuntu",
        ssh_pkey="final2.pem",
        local_bind_address=('127.0.0.1', 3306),
        remote_bind_address=('127.0.0.1', 3306)
    ) as tunnel_to_master:
        tunnel_to_master.start()
        connection = pymysql.connect(
        host = "127.0.0.1",
        user="root",
        password="TempPass",
        db="sakila",
        port=3306,
        autocommit=True
        )
        cursor = connection.cursor()
        cursor.execute(query)
        output = cursor.fetchall()
        print(f"Here is the output of query: {output}")
        connection.close()
        tunnel_to_master.close()

    

def main():
    if len(sys.argv) < 2:
        print('Correct format is: python(or python3) main.py "Example_of_query"')
    else:
        Query_SQL = sys.argv[1]
        direct_hit_strategy(Query_SQL)
        

if __name__ == "__main__":
    main()