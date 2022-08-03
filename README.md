# ecr-registry-refresh
Attempt at solution to handle refreshing ecr credentials


```
kubectl get secrets $GITPOD_REG_SECRET_NAME -n gitpod -o "jsonpath={.data.\.dockerconfigjson}" | \
    base64 -d | \
    jq -r .
```