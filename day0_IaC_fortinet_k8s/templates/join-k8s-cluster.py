# --------------------------------------------------------------------------------------------
# Retrieves necessary parameters from a Redis DB
# jvigueras@fortinet.com
# --------------------------------------------------------------------------------------------
import base64
import redis
import os
import time


def connect_db(host, port, password):
    """ Connect to Redis DB """
    try:
        response = redis.Redis(host=host, port=port, password=password)
        return response
    except Exception as e:
        print(f"Failed to connect to Redis: {e}")
        return None
    
def read_db(db_conn, key):
    """ Read key_value from Redis DB """
    try:
        value = db_conn.get(key)
        if value:
            return value.decode('utf-8')
        else:
            print(f'Key "{key}" does not exist in Redis.')
            return None
    except Exception as e:
        print(f'Error reading key-value pairs to Redis: {e}')    
        return None

def write_to_file(file_path, content):
    """ Writes content to a file """
    try:
        with open(file_path, "w") as f:
            f.write(content)
    except Exception as e:
        print(f"Failed to write content to file {file_path}: {e}")

def main():
    host       = '${db_host}'
    port       = '${db_port}'
    password   = '${db_pass}'
    prefix     = '${db_prefix}'
    separator  = '_'
    sleep_time = 20

    # Loop until DB is ready
    db_conn = None
    while db_conn is None:
        db_conn = connect_db(host, port, password)
        time.sleep(sleep_time)

    # Loop until master_host is populated
    master_host = None
    while master_host is None:
        master_host = read_db(db_conn, prefix+separator+'master_host')
        time.sleep(sleep_time)

    # Write value to file
    write_to_file("/tmp/master", master_host)

    # Loop until ca_cert is populated
    master_ca_cert = None
    while master_ca_cert is None:
        master_ca_cert = read_db(db_conn, prefix+separator+'master_ca_cert')
        time.sleep(sleep_time)

    # Write value to file
    write_to_file("/tmp/cert.crt", base64.b64decode(master_ca_cert).decode())

    # Loop until master token is populated
    master_token = None
    while master_token is None:
        master_token = read_db(db_conn, prefix+separator+'master_token')
        time.sleep(sleep_time)

    # Write value to file
    write_to_file("/tmp/token", master_token)

if __name__ == "__main__":
    main()