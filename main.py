import boto3
from kubernetes import client, config
from pprint import pprint

ecr_client = boto3.client('ecr')

def main():
    config.load_config()

    v1 = client.CoreV1Api()
    print("Listing pods with their IPs:")
    ret = v1.list_pod_for_all_namespaces(watch=False)
    for i in ret.items:
        print("%s\t%s\t%s" %
              (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
    
    api_response = v1.read_namespaced_secret('container-registry', 'gitpod')
    pprint(api_response)


    response = ecr_client.get_authorization_token()

    pprint(response)


if __name__ == '__main__':
    main()