# --------------------------------------------------------------------------------------------
# Populate cluster data to Redis DB
#
# jvigueras@fortinet.com
# --------------------------------------------------------------------------------------------
import base64
import redis
import kubernetes
from kubernetes import client, config

def get_bootstrap_token():
    """ Get the token id from the Kubernetes cluster """
    kube_client = client.CoreV1Api()
    master_tokens = kube_client.list_namespaced_secret("kube-system", field_selector='type=bootstrap.kubernetes.io/token').items
    master_token_id = base64.b64decode(master_tokens[0].data["token-id"]).decode()
    master_token_secret = base64.b64decode(master_tokens[0].data["token-secret"]).decode()
    return  master_token_id + "." + master_token_secret

def get_cicd_token():
    """ Get the CICD token from the Kubernetes cluster """
    kube_client = client.CoreV1Api()
    cicd_token = kube_client.read_namespaced_secret(name="cicd-access", namespace="default").data["token"]
    cicd_token_decode = base64.b64decode(cicd_token).decode()
    return cicd_token_decode

def get_cicd_cert():
    """ Get the CICD certificate from the Kubernetes cluster """
    kube_client = client.CoreV1Api()
    cicd_cert = kube_client.read_namespaced_secret(name="cicd-access", namespace="default").data["ca.crt"]
    return cicd_cert

def connect_db(host, port, password):
    """ Connect to Redis DB """
    try:
        r = redis.Redis(host=host, port=port, password=password)
        return r
    except Exception as e:
        print(f"Failed to connect to Redis: {e}")
        return None

def write_db(db_conn, key_value_pairs):
    """ Write key-value pairs to Redis """
    try:
        for key, value in key_value_pairs.items():
            db_conn.set(key, value)
    except Exception as e:
        print(f'Error writing key-value pairs to Redis: {e}')

def main():
    try:
        # Load the Kubernetes configuration
        config.load_kube_config()

        # Get the tokens and certificate from Kubernetes
        cicd_token = get_cicd_token()
        cicd_cert = get_cicd_cert()
        master_token = get_bootstrap_token()
        master_host = '${master_ip}:${master_api_port}'

        # Write key-pairs to Redis DB
        host = '${db_host}'
        port = '${db_port}'
        password = '${db_pass}'
        prefix = '${db_prefix}'
        separator = '_'

        db_conn = connect_db(host,port,password)
        if db_conn:
             # Define the key-value pairs to write
            key_value_pairs = {
                prefix+separator+'cicd-access_token': cicd_token,
                prefix+separator+'master_ca_cert' : cicd_cert,
                prefix+separator+'master_token': master_token,
                prefix+separator+'master_host' : master_host,
            }
            write_db(db_conn,key_value_pairs)

    except Exception as e:
        print(f"Failed to execute main function: {e}")

if __name__ == '__main__':
    main()