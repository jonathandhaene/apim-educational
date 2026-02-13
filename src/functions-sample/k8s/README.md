# Kubernetes Deployment for Azure Functions

This directory contains Kubernetes manifests for deploying the Azure Function sample to AKS (Azure Kubernetes Service) or any other Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (AKS, Minikube, or any K8s cluster)
- kubectl configured to connect to your cluster
- Docker installed locally
- Azure Container Registry (ACR) or any container registry
- Azure Storage Account for Azure Functions runtime

## Files

- `deployment.yaml` - Kubernetes Deployment with best practices (readiness/liveness probes, resource limits)
- `service.yaml` - Kubernetes Service (LoadBalancer and ClusterIP)

## Quick Start

### 1. Build and Push Docker Image to ACR

```bash
# Login to Azure
az login

# Create Azure Container Registry (if not exists)
az acr create --resource-group <resource-group> --name <acr-name> --sku Basic

# Login to ACR
az acr login --name <acr-name>

# Build and tag the image
cd /home/runner/work/apim-educational/apim-educational/src/functions-sample
docker build -t <acr-name>.azurecr.io/azure-function-sample:latest .

# Push to ACR
docker push <acr-name>.azurecr.io/azure-function-sample:latest
```

### 2. Create Kubernetes Secret for ACR

```bash
# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name <acr-name> --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name <acr-name> --query passwords[0].value -o tsv)

# Create Kubernetes secret for pulling images from ACR
kubectl create secret docker-registry acr-secret \
  --docker-server=<acr-name>.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=<your-email>
```

### 3. Configure Azure Storage Connection String

Edit `deployment.yaml` and update the `function-secrets` Secret with your Azure Storage connection string:

```yaml
stringData:
  storage-connection-string: "DefaultEndpointsProtocol=https;AccountName=<your-storage-account>;AccountKey=<your-key>;EndpointSuffix=core.windows.net"
```

**Note**: For production, use Azure Key Vault with:
- [Azure Key Vault CSI Driver](https://docs.microsoft.com/azure/aks/csi-secrets-store-driver)
- [External Secrets Operator](https://external-secrets.io/)

### 4. Update Image Reference

Edit `deployment.yaml` and replace `<your-acr-name>` with your actual ACR name:

```yaml
image: <your-acr-name>.azurecr.io/azure-function-sample:latest
```

### 5. Deploy to Kubernetes

```bash
# Apply deployment
kubectl apply -f k8s/deployment.yaml

# Apply service
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### 6. Access the Function

#### For LoadBalancer service:

```bash
# Get external IP
kubectl get service azure-function-sample

# Test the function
EXTERNAL_IP=$(kubectl get service azure-function-sample -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl "http://$EXTERNAL_IP/api/httpTrigger?name=Kubernetes"
```

#### For ClusterIP service (internal access):

```bash
# Port forward
kubectl port-forward service/azure-function-sample-internal 8080:80

# Test the function
curl "http://localhost:8080/api/httpTrigger?name=Kubernetes"
```

## Best Practices Implemented

### 1. Resource Limits and Requests

The deployment specifies resource constraints to ensure predictable performance:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 2. Readiness Probe

Ensures traffic is only sent to healthy pods:

```yaml
readinessProbe:
  httpGet:
    path: /api/httpTrigger?name=HealthCheck
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
```

### 3. Liveness Probe

Automatically restarts unhealthy pods:

```yaml
livenessProbe:
  httpGet:
    path: /api/httpTrigger?name=HealthCheck
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 30
```

### 4. Multiple Replicas

High availability with 2 replicas:

```yaml
replicas: 2
```

### 5. Image Pull Secrets

Secure access to private container registries:

```yaml
imagePullSecrets:
- name: acr-secret
```

## Testing Locally with Minikube

If you want to test locally before deploying to AKS:

```bash
# Start Minikube
minikube start

# Build image in Minikube's Docker
eval $(minikube docker-env)
docker build -t azure-function-sample:latest .

# Update deployment.yaml to use local image
# Change imagePullPolicy to IfNotPresent and remove ACR reference

# Deploy
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Access via Minikube
minikube service azure-function-sample
```

## Deploying to AKS

### Create AKS Cluster

```bash
# Create resource group
az group create --name rg-aks-functions --location eastus

# Create AKS cluster
az aks create \
  --resource-group rg-aks-functions \
  --name aks-functions-cluster \
  --node-count 2 \
  --enable-managed-identity \
  --attach-acr <acr-name> \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group rg-aks-functions --name aks-functions-cluster
```

### Deploy to AKS

```bash
# Deploy the function
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Monitor deployment
kubectl get pods -w
```

## Monitoring and Logs

```bash
# View logs
kubectl logs -l app=azure-function-sample -f

# Describe pod for detailed info
kubectl describe pod <pod-name>

# Check resource usage
kubectl top pods
kubectl top nodes
```

## Scaling

### Manual Scaling

```bash
# Scale to 5 replicas
kubectl scale deployment azure-function-sample --replicas=5
```

### Horizontal Pod Autoscaler

```bash
# Create HPA (requires metrics server)
kubectl autoscale deployment azure-function-sample \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# Check HPA status
kubectl get hpa
```

## Integration with APIM

Once deployed to Kubernetes, you can configure APIM to use the Kubernetes service as a backend:

1. **For LoadBalancer**: Use the external IP as the backend URL in APIM
2. **For ClusterIP with Ingress**: Configure an Ingress controller and use the ingress URL
3. **For private AKS**: Use APIM VNet integration to reach ClusterIP services

### Example APIM Backend Configuration

```xml
<backend>
  <forward-request>
    <set-backend-service base-url="http://<external-ip-or-ingress>/api" />
  </forward-request>
</backend>
```

## Security Considerations

### Production Recommendations

1. **Use Azure Key Vault for Secrets**:
   - Install CSI driver: `az aks enable-addons --addons azure-keyvault-secrets-provider`
   - Mount secrets as volumes instead of environment variables

2. **Enable Pod Security Policies**:
   - Restrict privileged containers
   - Enforce read-only root filesystems where possible

3. **Network Policies**:
   - Limit pod-to-pod communication
   - Use Azure Network Policy or Calico

4. **Use Managed Identity**:
   - Enable workload identity for AKS
   - Avoid storing credentials in secrets

5. **Private Cluster**:
   - Deploy AKS as private cluster
   - Use private endpoints for ACR

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common issues:
# - Image pull errors: Check ACR credentials
# - CrashLoopBackOff: Check application logs and environment variables
```

### Service Not Accessible

```bash
# Check service
kubectl describe service azure-function-sample

# Check endpoints
kubectl get endpoints azure-function-sample

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://azure-function-sample-internal/api/httpTrigger?name=Test
```

### Storage Connection Issues

```bash
# Verify secret exists
kubectl get secret function-secrets

# Check secret content
kubectl get secret function-secrets -o yaml

# Test storage connectivity from pod
kubectl exec -it <pod-name> -- /bin/sh
# Then try to connect to storage
```

## Clean Up

```bash
# Delete deployments and services
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml

# Delete secrets
kubectl delete secret acr-secret
kubectl delete secret function-secrets

# Delete AKS cluster (if created for testing)
az aks delete --resource-group rg-aks-functions --name aks-functions-cluster --yes --no-wait
```

## Additional Resources

- [Azure Functions on Kubernetes](https://docs.microsoft.com/azure/azure-functions/functions-kubernetes-keda)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
