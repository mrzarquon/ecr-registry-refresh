# ecr-registry-refresh
Attempt at solution to handle refreshing ecr credentials


```
kubectl get secrets container-registry -n gitpod -o "jsonpath={.data.\.dockerconfigjson}" | \
    base64 -d | \
    jq -r .
```


debug in as:
kubectl apply -f test_pod.yaml 
kubectl exec -it ecr-helper-debug -n gitpod -- aws sts get-caller-identity
