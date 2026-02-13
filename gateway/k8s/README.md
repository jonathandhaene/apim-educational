# Self-Hosted Gateway on Kubernetes/AKS

This directory contains configuration for deploying Azure API Management Self-Hosted Gateway on Kubernetes.

## Prerequisites

- Kubernetes cluster (AKS, on-premises, or other)
- kubectl configured
- APIM instance with gateway created

## Steps

### 1. Create Gateway in APIM

```bash
# Via Azure Portal
# Navigate to: API Management → Gateways → Add
# Name: on-prem-gateway
# Generate key

# Or via Azure CLI
az apim gateway create \
  --resource-group rg-apim \
  --service-name apim-instance \
  --gateway-id on-prem-gateway \
  --location-data name="On-Premises" city="Seattle" region="US-West"
```

### 2. Get Gateway Configuration

From Azure Portal:
1. Navigate to gateway
2. Click "Deployment"
3. Copy Kubernetes YAML or Helm values

### 3. Deploy with Kubernetes

```bash
# Create namespace
kubectl create namespace apim-gateway

# Create secret with gateway token
kubectl create secret generic apim-gateway-token \
  --from-literal=value="GatewayKey ..." \
  --namespace apim-gateway

# Apply deployment (get YAML from portal or use Helm)
kubectl apply -f gateway-deployment.yaml
```

### 4. Deploy with Helm

```bash
# Add APIM Helm repository
helm repo add apim https://azure.github.io/api-management-self-hosted-gateway/helm-charts/
helm repo update

# Install
helm install apim-gateway apim/azure-api-management-gateway \
  --namespace apim-gateway \
  --set gateway.endpoint="<management-endpoint>" \
  --set gateway.authKey.value="<gateway-key>"
```

## Configuration

Placeholder for:
- `gateway-deployment.yaml`: Kubernetes deployment manifest
- `gateway-service.yaml`: Kubernetes service
- `gateway-ingress.yaml`: Ingress configuration
- `helm-values.yaml`: Helm chart values

These files should be customized based on your APIM gateway configuration from the Azure Portal.

## Monitoring

- Gateway logs: `kubectl logs -n apim-gateway deployment/apim-gateway`
- Gateway metrics: Available in Azure Monitor
- Health check: `kubectl get pods -n apim-gateway`

## Troubleshooting

**Gateway not connecting:**
- Verify management endpoint URL
- Check gateway token is correct
- Ensure network connectivity to Azure

**APIs not available:**
- Verify APIs are published to the gateway
- Check gateway synchronization status in portal

## References

- [Self-Hosted Gateway Docs](https://learn.microsoft.com/azure/api-management/self-hosted-gateway-overview)
- [Kubernetes Deployment](https://learn.microsoft.com/azure/api-management/how-to-deploy-self-hosted-gateway-kubernetes)
- [AKS Integration](https://learn.microsoft.com/azure/api-management/how-to-deploy-self-hosted-gateway-azure-kubernetes-service)
