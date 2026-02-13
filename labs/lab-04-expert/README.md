# Lab 4: Expert - Self-Hosted Gateway, Front Door, and Performance Optimization

**Level**: Expert  
**Duration**: 120-150 minutes  
**Prerequisites**: Completed Lab 3 or have APIM with advanced configuration

## Learning Objectives

By the end of this lab, you will:
- Deploy and configure self-hosted gateway using Docker Compose
- Deploy self-hosted gateway to Azure Kubernetes Service (AKS)
- Integrate Azure Front Door with APIM for global distribution
- Implement blue/green deployment strategy using revisions
- Optimize performance with caching and backend pool strategies
- Understand on-premises/hybrid deployment patterns

## Architecture

```
Global Users
    ↓
Azure Front Door (WAF)
    ↓
APIM (Multi-region)
    ├── Cloud Gateway
    └── Self-Hosted Gateway
            ├── Docker (Local/Edge)
            └── Kubernetes (AKS/On-prem)
                ↓
            Backend APIs
```

## Prerequisites

- Completed [Lab 3: Advanced](../lab-03-advanced/README.md)
- Docker Desktop installed and running
- kubectl and Azure CLI installed
- AKS cluster (or ability to create one)
- Premium tier APIM (for multi-region and self-hosted gateway)

## Step 1: Deploy Self-Hosted Gateway with Docker

### Create Gateway Resource in APIM

```bash
# Set variables
RESOURCE_GROUP="rg-apim-lab"
APIM_NAME="apim-lab-yourname"
GATEWAY_NAME="selfhosted-gateway"

# Create gateway configuration in APIM
az apim gateway create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --gateway-id ${GATEWAY_NAME} \
  --description "Self-hosted gateway for edge/on-prem" \
  --location-data '{"name": "Local Datacenter", "city": "On-premises"}'

echo "Gateway created: ${GATEWAY_NAME}"
```

### Get Gateway Token

```bash
# Generate gateway token (valid for 30 days)
TOKEN=$(az apim gateway token create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --gateway-id ${GATEWAY_NAME} \
  --expiry $(date -u -d "+30 days" +%Y-%m-%dT%H:%M:%SZ) \
  --key primary \
  --query value -o tsv)

echo "Gateway Token: ${TOKEN}"
# Store this securely - you'll need it for docker-compose
```

### Configure Docker Compose

Use the provided docker-compose.yml from [../../gateway/docker-compose.yml](../../gateway/docker-compose.yml) or create:

```bash
cd ../../gateway

# Create .env file with your values
cat > .env <<EOF
APIM_NAME=${APIM_NAME}
GATEWAY_TOKEN=${TOKEN}
GATEWAY_NAME=${GATEWAY_NAME}
APIM_REGION=eastus
EOF

# Review docker-compose.yml configuration
cat docker-compose.yml
```

### Start Self-Hosted Gateway

```bash
# Start the gateway
docker-compose up -d

# Check logs
docker-compose logs -f apim-gateway

# Verify gateway is running
docker-compose ps
```

### Validation

```bash
# Check gateway health
curl http://localhost:8080/status-0123456789abcdef

# Expected: 200 OK with gateway status

# Assign API to self-hosted gateway
az apim gateway api create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --gateway-id ${GATEWAY_NAME} \
  --api-id sample-api

# Test API through self-hosted gateway
curl "http://localhost:8080/sample/httpTrigger?name=SelfHosted" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

**Expected Output**: API call succeeds through local self-hosted gateway, logs appear in docker-compose logs.

## Step 2: Deploy Self-Hosted Gateway to Kubernetes

### Create AKS Cluster

```bash
# Create AKS cluster
AKS_NAME="aks-apim-gateway"
az aks create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${AKS_NAME} \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --enable-managed-identity \
  --generate-ssh-keys

# Get credentials
az aks get-credentials \
  --resource-group ${RESOURCE_GROUP} \
  --name ${AKS_NAME} \
  --overwrite-existing

# Verify connection
kubectl get nodes
```

### Deploy Gateway to Kubernetes

```bash
cd ../../gateway/k8s

# Create namespace
kubectl create namespace apim-gateway

# Create secret with gateway token
kubectl create secret generic apim-gateway-token \
  --from-literal=value="${TOKEN}" \
  --namespace apim-gateway

# Create ConfigMap with APIM configuration
kubectl create configmap apim-gateway-config \
  --from-literal=config.service.endpoint="https://${APIM_NAME}.management.azure-api.net/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}?api-version=2021-08-01" \
  --namespace apim-gateway

# Deploy gateway using provided manifests
kubectl apply -f deployment.yaml -n apim-gateway
kubectl apply -f service.yaml -n apim-gateway

# Check deployment
kubectl get pods -n apim-gateway
kubectl get svc -n apim-gateway
```

### Expose Gateway with LoadBalancer

```bash
# Gateway service should have LoadBalancer type
# Get external IP
GATEWAY_EXTERNAL_IP=$(kubectl get svc apim-gateway -n apim-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Gateway External IP: ${GATEWAY_EXTERNAL_IP}"

# Test API through Kubernetes gateway
curl "http://${GATEWAY_EXTERNAL_IP}/sample/httpTrigger?name=K8sGateway" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

**Expected Output**: API call succeeds through Kubernetes-hosted gateway.

## Step 3: Integrate Azure Front Door

### Create Front Door Profile

```bash
# Create Front Door (Standard tier)
FD_NAME="fd-apim-${RANDOM}"
az afd profile create \
  --profile-name ${FD_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --sku Standard_AzureFrontDoor

# Create endpoint
az afd endpoint create \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME} \
  --endpoint-name api-endpoint \
  --enabled-state Enabled

# Get endpoint hostname
FD_ENDPOINT=$(az afd endpoint show \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME} \
  --endpoint-name api-endpoint \
  --query hostName -o tsv)

echo "Front Door Endpoint: ${FD_ENDPOINT}"
```

### Configure Origin Group and Origins

```bash
# Create origin group
az afd origin-group create \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME} \
  --origin-group-name apim-origins \
  --probe-request-type GET \
  --probe-protocol Https \
  --probe-interval-in-seconds 30 \
  --probe-path "/status-0123456789abcdef" \
  --sample-size 4 \
  --successful-samples-required 3 \
  --additional-latency-in-milliseconds 50

# Add APIM as origin
az afd origin create \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME} \
  --origin-group-name apim-origins \
  --origin-name apim-primary \
  --host-name "${APIM_NAME}.azure-api.net" \
  --origin-host-header "${APIM_NAME}.azure-api.net" \
  --priority 1 \
  --weight 1000 \
  --enabled-state Enabled \
  --http-port 80 \
  --https-port 443
```

### Create Route

```bash
# Create route to forward traffic to APIM
az afd route create \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME} \
  --endpoint-name api-endpoint \
  --route-name default-route \
  --origin-group apim-origins \
  --supported-protocols Https \
  --link-to-default-domain Enabled \
  --forwarding-protocol HttpsOnly \
  --https-redirect Enabled

echo "Front Door configured successfully"
```

### Enable WAF Policy (Optional)

```bash
# Create WAF policy
az network front-door waf-policy create \
  --resource-group ${RESOURCE_GROUP} \
  --name wafapim \
  --sku Standard_AzureFrontDoor \
  --disabled false \
  --mode Prevention

# Get policy ID
POLICY_ID=$(az network front-door waf-policy show \
  --resource-group ${RESOURCE_GROUP} \
  --name wafapim \
  --query id -o tsv)

# Link WAF policy to endpoint
az afd security-policy create \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME} \
  --security-policy-name waf-policy \
  --domains $(az afd endpoint show --resource-group ${RESOURCE_GROUP} --profile-name ${FD_NAME} --endpoint-name api-endpoint --query id -o tsv) \
  --waf-policy ${POLICY_ID}
```

### Test Front Door Integration

```bash
# Test API through Front Door
curl "https://${FD_ENDPOINT}/sample/httpTrigger?name=FrontDoor" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Check Front Door headers in response
curl -v "https://${FD_ENDPOINT}/sample/httpTrigger?name=Headers" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  2>&1 | grep "X-Azure-FDID"
```

**Expected Output**: API calls succeed through Front Door, response includes `X-Azure-FDID` header.

## Step 4: Blue/Green Deployment with Revisions

### Setup Blue/Green Strategy

```bash
# Current production = Blue (revision 1)
# Create Green deployment (revision 2) with new features

# Create revision 2 (Green)
az apim api revision create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api \
  --api-revision 2 \
  --api-revision-description "Green deployment with new features"

# Apply different policy to Green (e.g., new rate limits, transformations)
# Navigate to APIM → APIs → sample-api;rev=2 → Policies
```

### Test Green Deployment

```bash
# Test Green (revision 2) - only via specific revision URL
curl "https://${APIM_NAME}.azure-api.net/sample;rev=2/httpTrigger?name=Green" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Blue (revision 1) still serves production traffic
curl "https://${APIM_NAME}.azure-api.net/sample/httpTrigger?name=Blue" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"
```

### Run Load Test on Green

```bash
cd ../../tests/k6

# Set environment for Green deployment
export APIM_URL="https://${APIM_NAME}.azure-api.net"
export API_PATH="/sample;rev=2/httpTrigger"
export SUBSCRIPTION_KEY="${SUBSCRIPTION_KEY}"

# Run load test
k6 run --vus 50 --duration 60s load-test.js

# Analyze results and compare with Blue
```

### Promote Green to Production

```bash
# If Green tests pass, make it current (Blue → Green cutover)
az apim api release create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api \
  --api-revision 2 \
  --notes "Promoted Green deployment to production"

# Now revision 2 is current, revision 1 becomes previous
# Traffic now flows to Green automatically
```

### Rollback Strategy

```bash
# If issues found, rollback to Blue (revision 1)
az apim api release create \
  --resource-group ${RESOURCE_GROUP} \
  --service-name ${APIM_NAME} \
  --api-id sample-api \
  --api-revision 1 \
  --notes "Rollback to previous stable version (Blue)"

# Traffic switches back to revision 1 (Blue)
```

## Step 5: Performance Optimization with Caching

### Configure Response Caching

See complete caching policy in [../../policies/cache.xml](../../policies/cache.xml).

```xml
<policies>
    <inbound>
        <base />
        <!-- Cache lookup with vary-by parameters -->
        <cache-lookup vary-by-developer="false" 
                      vary-by-developer-groups="false"
                      downstream-caching-type="none">
            <vary-by-query-parameter>name</vary-by-query-parameter>
            <vary-by-query-parameter>category</vary-by-query-parameter>
        </cache-lookup>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <!-- Cache responses for 5 minutes -->
        <cache-store duration="300" />
    </outbound>
</policies>
```

### Configure External Cache (Redis)

```bash
# Create Azure Cache for Redis
REDIS_NAME="redis-apim-${RANDOM}"
az redis create \
  --resource-group ${RESOURCE_GROUP} \
  --name ${REDIS_NAME} \
  --location ${LOCATION} \
  --sku Basic \
  --vm-size c0

# Get Redis connection string
REDIS_CONN=$(az redis list-keys \
  --resource-group ${RESOURCE_GROUP} \
  --name ${REDIS_NAME} \
  --query primaryKey -o tsv)

# Configure external cache in APIM
# Navigate to: APIM → External cache → Add
# Connection string: {redis-name}.redis.cache.windows.net:6380,password={key},ssl=True,abortConnect=False

# Use external cache in policy:
# <cache-lookup use-external-cache="true" ... />
```

### Test Caching Performance

```bash
# First request (cache miss)
time curl "https://${APIM_NAME}.azure-api.net/sample/httpTrigger?name=CacheTest" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Second request (cache hit - should be faster)
time curl "https://${APIM_NAME}.azure-api.net/sample/httpTrigger?name=CacheTest" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}"

# Check cache headers
curl -I "https://${APIM_NAME}.azure-api.net/sample/httpTrigger?name=CacheTest" \
  -H "Ocp-Apim-Subscription-Key: ${SUBSCRIPTION_KEY}" \
  | grep "X-Cache"
```

**Expected Output**: Second request is significantly faster, `X-Cache: HIT` header present.

## Step 6: Backend Pool and Load Balancing

### Configure Backend Pool

```xml
<policies>
    <inbound>
        <base />
        <!-- Load balance across multiple backends -->
        <set-backend-service backend-id="backend-pool" />
    </inbound>
</policies>
```

Create backend pool via Portal:
1. APIM → Backends → Add → Backend pool
2. Add multiple backend URLs
3. Configure load balancing algorithm (round-robin, weighted, priority)

See [networking documentation](../../docs/networking.md) for more details.

## Step 7: Cleanup

```bash
# Stop and remove Docker containers
cd ../../gateway
docker-compose down -v

# Delete AKS cluster
az aks delete \
  --resource-group ${RESOURCE_GROUP} \
  --name ${AKS_NAME} \
  --yes --no-wait

# Delete Front Door
az afd profile delete \
  --resource-group ${RESOURCE_GROUP} \
  --profile-name ${FD_NAME}

# Delete entire resource group (or keep for Lab 5)
# az group delete --name ${RESOURCE_GROUP} --yes --no-wait
```

## 🎓 What You Learned

- ✅ Deployed self-hosted gateway with Docker Compose
- ✅ Deployed self-hosted gateway to Kubernetes (AKS)
- ✅ Integrated Azure Front Door with WAF for global distribution
- ✅ Implemented blue/green deployment with API revisions
- ✅ Configured response caching for performance optimization
- ✅ Set up external cache with Azure Redis
- ✅ Understood backend pool and load balancing strategies

## 📚 Next Steps

Continue to [Lab 5: Operations & Architecture](../lab-05-ops-architecture/README.md) to learn about:
- Azure API Center synchronization
- AI Gateway policies for LLM APIs
- Advanced observability with KQL
- Disaster recovery and business continuity
- Cost optimization strategies

## 📖 Additional Resources

- [Self-Hosted Gateway](https://learn.microsoft.com/azure/api-management/self-hosted-gateway-overview)
- [Front Door + APIM](../../docs/front-door.md)
- [Caching Policies](https://learn.microsoft.com/azure/api-management/api-management-caching-policies)
- [API Revisions](https://learn.microsoft.com/azure/api-management/api-management-revisions)
- [Kubernetes Deployment](../../gateway/k8s/README.md)

## ❓ Troubleshooting

**Issue**: Self-hosted gateway not connecting  
**Solution**: Check token validity, ensure APIM allows outbound connectivity, verify firewall rules

**Issue**: Kubernetes gateway pods failing  
**Solution**: Check secret creation, verify APIM endpoint URL in ConfigMap, review pod logs

**Issue**: Front Door not routing to APIM  
**Solution**: Verify origin hostname matches APIM, check probe path returns 200, allow Front Door IPs in APIM

**Issue**: Cache not working  
**Solution**: Ensure cache-lookup is before cache-store, check vary-by parameters, verify cache duration

---

**Congratulations!** You're now an APIM expert! Ready for the final lab on operations? 🚀
