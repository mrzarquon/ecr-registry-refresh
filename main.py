#!/usr/bin/env python

import boto3
import base64
import json
import os

from kubernetes import client, config
from pprint import pprint



def extract_config(data: str) -> dict:
    config_dict = json.loads(decode64(data['.dockerconfigjson']))
    return config_dict

def decode64(encoded: str) -> str:
    decoded_bytes = base64.b64decode(encoded)
    decoded = decoded_bytes.decode('utf-8')
    return decoded

def encode64(decoded: str) -> str:
    decoded_bytes = decoded.encode('utf-8')
    encoded = base64.b64encode(decoded_bytes)
    return encoded.decode('utf-8')

def get_env_vars() -> dict:
    vars = {}
    vars['server'] = os.environ['ECR_HELPER_SERVER']
    vars['secret-name'] = os.environ['GITPOD_REG_SECRET_NAME']
    if "ECR_HELPER_DEBUG" in os.environ.keys(): 
        vars['debug'] = str2bool(os.environ['ECR_HELPER_DEBUG'])
    else:
        vars['debug'] = False

    return vars

def get_ecr_token() -> str:
    ecr_client = boto3.client('ecr')
    auth_data = ecr_client.get_authorization_token()
    token = auth_data['authorizationData'][0]['authorizationToken']
    return token

def str2bool(v):
  return v.lower() in ("yes", "true", "t", "1")


def main():

    settings = get_env_vars()

    server = settings['server']
    secret = settings['secret-name']
    debug = settings['debug']

    v1 = client.CoreV1Api()

    if debug:
        config.load_config()
    else:
        config.load_incluster_config()

    
    api_response = v1.read_namespaced_secret(secret, 'gitpod')
    
    data = extract_config(api_response.data)

    if server in data['auths'].keys():
        print(f'{server} has a secret, lets update it')
        data['auths'][server]['password'] = get_ecr_token()
        new_auth = encode64(f"aws:{data['auths'][server]['password']}")
        data['auths'][server]['auth'] = new_auth


    patch = {
        'data' : {
            '.dockerconfigjson':
                encode64(json.dumps(data))
        }
    }

    patch_secret = v1.patch_namespaced_secret(secret,'gitpod', patch)

    pprint(patch_secret)


if __name__ == '__main__':
    main()