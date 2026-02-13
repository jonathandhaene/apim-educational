# Azure API Management Troubleshooting Guide

Common issues, diagnostics, and solutions for Azure API Management.

## Table of Contents
- [General Troubleshooting Approach](#general-troubleshooting-approach)
- [Connectivity Issues](#connectivity-issues)
- [Authentication Failures](#authentication-failures)
- [Performance Problems](#performance-problems)
- [Policy Errors](#policy-errors)
- [Deployment Issues](#deployment-issues)
- [Diagnostic Tools](#diagnostic-tools)

## General Troubleshooting Approach

### Systematic Debugging Process

1. **Identify the Symptom**: What's the error message or unexpected behavior?
2. **Check Status**: Is APIM itself healthy?
3. **Review Logs**: Check Application Insights and Log Analytics
4. **Isolate the Layer**: Is it client, APIM, backend, or network?
5. **Test Incrementally**: Bypass APIM, test backend directly
6. **Check Recent Changes**: What changed before the issue appeared?

### Quick Health Check

```bash
# Check APIM status
az apim show --name <apim-name> --resource-group <rg> --query "{name:name, state:provisioningState, status:runtimeStatus}"

# Test gateway endpoint
curl -I https://<apim-name>.azure-api.net/echo/resource

# Check diagnostics
az monitor diagnostic-settings list --resource <apim-resource-id>
```

## Connectivity Issues

### Issue: Cannot Reach Gateway

**Symptoms:**
- Connection timeout
- "Site can't be reached"
- DNS resolution failures

**Diagnostic Steps:**
```bash
# Test DNS resolution
nslookup <apim-name>.azure-api.net

# Test connectivity
curl -v https://<apim-name>.azure-api.net

# Check from Azure Cloud Shell (rules out local network)
```

**Common Causes & Solutions:**

1. **DNS Not Configured**
   - Solution: Wait for DNS propagation (up to 48 hours)
   - Verify CNAME or A records are correct

2. **NSG Blocking Traffic (VNet scenarios)**
   - Solution: Check NSG rules allow port 443 from source
   - Required inbound: 80, 443, 3443
   - Required outbound: Storage, SQL, Key Vault, EventHub

3. **Custom Domain Certificate Issues**
   - Solution: Verify certificate is valid and trusted
   - Check certificate chain is complete
   - Ensure Key Vault access via Managed Identity

4. **Private Endpoint Not Configured**
   - Solution: Create private DNS zone and link to VNet
   - Verify private endpoint connection approved
   - Test from VM within VNet

### Issue: Intermittent Connectivity

**Symptoms:**
- Works sometimes, fails other times
- Random timeouts

**Common Causes:**
- Backend service intermittent availability
- Network path instability
- Rate limiting triggered
- Capacity limits reached

**Solutions:**
```xml
<!-- Add retry policy -->
<policies>
  <inbound>
    <retry condition="@(context.Response.StatusCode >= 500)" count="3" interval="1" delta="1" />
  </inbound>
</policies>
```

## Authentication Failures

### Issue: 401 Unauthorized

**Symptoms:**
- "Access denied" or "Unauthorized"
- 401 status code

**Diagnostic Steps:**
```xml
<!-- Add logging to see what's received -->
<policies>
  <inbound>
    <trace source="auth-debug">
      <message>@($"Auth header: {context.Request.Headers.GetValueOrDefault("Authorization", "MISSING")}")</message>
    </trace>
  </inbound>
</policies>
```

**Common Causes & Solutions:**

1. **Missing Subscription Key**
   - Solution: Add `Ocp-Apim-Subscription-Key` header or query param
   - Check key is valid (not regenerated)

2. **Invalid JWT Token**
   - Expired token: Check token `exp` claim
   - Wrong audience: Verify `aud` claim matches expected value
   - Wrong issuer: Check `iss` claim
   - Missing required claims: Verify `roles` or `scp` claims

**Debug JWT Validation:**
```xml
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Token validation failed" output-token-variable-name="jwt">
      <openid-config url="https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration" />
    </validate-jwt>
    <trace source="jwt-debug">
      <message>@{
        var jwt = (Jwt)context.Variables["jwt"];
        return $"Token claims: {string.Join(", ", jwt.Claims.Select(c => c.Type + "=" + c.Value))}";
      }</message>
    </trace>
  </inbound>
</policies>
```

3. **Certificate Issues (mTLS)**
   - Certificate not sent by client
   - Certificate expired or not trusted
   - Thumbprint mismatch

**Debug Certificate:**
```xml
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Request.Certificate == null)">
        <trace source="cert-debug"><message>No certificate provided</message></trace>
      </when>
      <otherwise>
        <trace source="cert-debug">
          <message>@($"Cert thumbprint: {context.Request.Certificate.Thumbprint}, Subject: {context.Request.Certificate.Subject}")</message>
        </trace>
      </otherwise>
    </choose>
  </inbound>
</policies>
```

### Issue: 403 Forbidden

**Symptoms:**
- Authenticated but not authorized
- 403 status code

**Common Causes:**
- JWT has wrong roles/scopes
- IP not in allowed list
- Quota exceeded
- Product subscription not active

## Performance Problems

### Issue: High Latency

**Symptoms:**
- Requests taking >2 seconds
- Timeouts occurring

**Diagnostic Query:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| summarize 
    AvgTotal = avg(TotalTime),
    AvgBackend = avg(BackendTime),
    AvgApim = avg(TotalTime - BackendTime),
    P95Total = percentile(TotalTime, 95)
  by ApiId
| order by P95Total desc
```

**Common Causes & Solutions:**

1. **Slow Backend**
   - If `BackendTime` is high: Optimize backend service
   - Add backend caching
   - Scale backend resources

2. **Complex Policies**
   - If `TotalTime - BackendTime` is high: Simplify policies
   - Avoid external calls in policies
   - Cache transformation results

3. **Network Latency**
   - Deploy multi-region (Premium tier)
   - Use Azure Front Door
   - Move backends closer to APIM

4. **Capacity Saturation**
   - Check Capacity metric (should be <70%)
   - Scale out (add units)
   - Implement caching

### Issue: High Error Rate

**Symptoms:**
- Many 500/502/503/504 errors
- Backend timeouts

**Diagnostic Query:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ResponseCode >= 500
| summarize Count = count() by ResponseCode, BackendResponseCode, ApiId
| order by Count desc
```

**Common Causes:**
- **502 Bad Gateway**: Backend not reachable or returned invalid response
- **503 Service Unavailable**: APIM capacity exceeded or backend overloaded
- **504 Gateway Timeout**: Backend took too long to respond

**Solutions:**
```xml
<!-- Increase timeout -->
<policies>
  <backend>
    <forward-request timeout="60" />
  </backend>
</policies>

<!-- Add circuit breaker -->
<policies>
  <inbound>
    <retry condition="@(context.Response.StatusCode >= 500)" count="3" interval="2" />
  </inbound>
</policies>
```

## Policy Errors

### Issue: Policy Execution Errors

**Symptoms:**
- 500 errors with policy name in message
- "Expression evaluation failed"

**Common Errors:**

1. **Null Reference**
```xml
<!-- BAD: Will fail if header doesn't exist -->
<set-variable name="userId" value="@(context.Request.Headers["X-User-Id"])" />

<!-- GOOD: Use GetValueOrDefault -->
<set-variable name="userId" value="@(context.Request.Headers.GetValueOrDefault("X-User-Id", ""))" />
```

2. **Invalid JSON**
```xml
<!-- Validate JSON before parsing -->
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Request.Body != null)">
        <set-variable name="bodyString" value="@(context.Request.Body.As<string>(preserveContent: true))" />
        <choose>
          <when condition="@{
            try {
              JObject.Parse((string)context.Variables["bodyString"]);
              return false;
            } catch {
              return true;
            }
          }">
            <return-response>
              <set-status code="400" reason="Invalid JSON" />
            </return-response>
          </when>
        </choose>
      </when>
    </choose>
  </inbound>
</policies>
```

3. **Send-Request Failures**
```xml
<!-- Check for errors -->
<policies>
  <inbound>
    <send-request mode="new" response-variable-name="authResponse" timeout="10" ignore-error="false">
      <set-url>https://auth-service.example.com/validate</set-url>
    </send-request>
    <choose>
      <when condition="@(context.Variables.ContainsKey("authResponse") == false || ((IResponse)context.Variables["authResponse"]).StatusCode != 200)">
        <return-response>
          <set-status code="500" reason="Auth service unavailable" />
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### Issue: Policy Not Applied

**Symptoms:**
- Policy XML saved but not taking effect
- Unexpected behavior

**Solutions:**
1. **Check Scope**: Policy might be overridden at a different scope (operation > API > product > global)
2. **Check Base Policy**: Ensure `<base />` is included where needed
3. **Clear Cache**: Browser/client caching might show old behavior
4. **Check Revisions**: Policy might be in different revision

## Deployment Issues

### Issue: VNet Injection Fails

**Symptoms:**
- "Failed to deploy to VNet"
- Deployment stuck in "Updating" state

**Common Causes & Solutions:**

1. **Subnet Not Empty**
   - Solution: Use dedicated subnet with no other resources

2. **NSG Rules Missing**
   - Solution: Add required inbound/outbound rules
   - See [Networking Guide](networking.md)

3. **Subnet Too Small**
   - Solution: Use /27 or larger subnet

4. **Service Endpoints Missing**
   - Solution: Enable Microsoft.Storage, Microsoft.Sql service endpoints

### Issue: Custom Domain Configuration Fails

**Symptoms:**
- Certificate validation errors
- "Failed to configure hostname"

**Solutions:**
1. **Certificate Issues**
   - Ensure certificate is valid and not expired
   - Include full certificate chain
   - Use PFX format or Key Vault reference

2. **Key Vault Access**
   - Grant APIM Managed Identity "Get Secrets" permission
   - Verify Key Vault network rules allow APIM

3. **DNS Configuration**
   - Add CNAME pointing to `<apim>.azure-api.net`
   - Wait for DNS propagation

## Diagnostic Tools

### Azure Portal

**APIM Overview Blade:**
- Health status
- Metrics dashboard
- Recent alerts

**Diagnose and Solve Problems:**
- Automated diagnostics
- Common issue detection
- Solution recommendations

### Azure CLI

```bash
# Get APIM status
az apim show --name <name> --resource-group <rg> \
  --query "{state:provisioningState,sku:sku.name,capacity:sku.capacity}"

# Check network status (VNet scenarios)
az apim show --name <name> --resource-group <rg> \
  --query "virtualNetworkConfiguration"

# View diagnostic settings
az monitor diagnostic-settings list \
  --resource <apim-resource-id>

# Get recent metrics
az monitor metrics list \
  --resource <apim-resource-id> \
  --metric Capacity,Requests,FailedRequests \
  --start-time "2024-01-01T00:00:00Z" \
  --end-time "2024-01-01T23:59:59Z"
```

### PowerShell

```powershell
# Get APIM instance
Get-AzApiManagement -ResourceGroupName <rg> -Name <name>

# Test network connectivity (VNet scenarios)
Test-AzNetworkWatcherConnectivity -ResourceGroupName <rg> `
  -Source <source-vm> -DestinationAddress <apim-private-ip> -DestinationPort 443

# Get diagnostics
Get-AzDiagnosticSetting -ResourceId <apim-resource-id>
```

### REST Client / cURL

```bash
# Test gateway with verbose output
curl -v https://<apim>.azure-api.net/api/endpoint \
  -H "Ocp-Apim-Subscription-Key: <key>"

# Test with trace enabled (if allowed)
curl -v https://<apim>.azure-api.net/api/endpoint \
  -H "Ocp-Apim-Subscription-Key: <key>" \
  -H "Ocp-Apim-Trace: true"

# View trace (from response header Ocp-Apim-Trace-Location)
curl -H "Ocp-Apim-Subscription-Key: <key>" \
  "<trace-url-from-header>"
```

### Test API Inspector (Azure Portal)

1. Navigate to APIM instance
2. Select API and operation
3. Click "Test" tab
4. Send request
5. View trace with detailed policy execution

## Logging and Monitoring

### Enable Debug Logging Temporarily

```xml
<!-- Add to policy for detailed logging -->
<policies>
  <inbound>
    <trace source="debug" severity="verbose">
      <message>@($"Request: {context.Request.Method} {context.Request.Url}")</message>
      <message>@($"Headers: {string.Join(", ", context.Request.Headers.Select(h => h.Key + "=" + string.Join(",", h.Value)))}")</message>
    </trace>
    <base />
  </inbound>
  <outbound>
    <base />
    <trace source="debug" severity="verbose">
      <message>@($"Response: {context.Response.StatusCode}")</message>
      <message>@($"Body: {context.Response.Body.As<string>(preserveContent: true)}")</message>
    </trace>
  </outbound>
</policies>
```

### View Logs in Application Insights

```kusto
// Recent errors
traces
| where timestamp > ago(1h)
| where severityLevel >= 3  // Warning or higher
| order by timestamp desc

// Policy traces
traces
| where timestamp > ago(1h)
| where message contains "policy"
| project timestamp, message, severityLevel
| order by timestamp desc
```

## Best Practices for Avoiding Issues

1. **Test in Non-Production First**: Always test changes in dev/test environment
2. **Use Revisions**: Deploy changes gradually with revisions
3. **Monitor Continuously**: Set up alerts before issues occur
4. **Document Configuration**: Maintain runbooks and architecture diagrams
5. **Keep Backups**: Export APIs and policies regularly
6. **Version Control**: Store policies in Git
7. **Validate Policies**: Test policy logic before deploying
8. **Review Logs Regularly**: Don't wait for alerts, proactively check logs
9. **Load Test**: Test at scale before production deployment
10. **Plan Capacity**: Monitor capacity metric and scale proactively

## Getting Help

### Microsoft Support

For production issues, create a support ticket:
```bash
az support tickets create \
  --ticket-name "APIM Gateway Errors" \
  --title "High error rate on APIM" \
  --severity "2" \
  --contact-first-name "..." \
  --contact-last-name "..." \
  --contact-method "email" \
  --contact-email "..." \
  --problem-classification "/providers/Microsoft.Support/services/{guid}/problemClassifications/{guid}"
```

### Community Resources

- [Microsoft Q&A](https://learn.microsoft.com/answers/topics/azure-api-management.html)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/azure-api-management)
- [GitHub Issues](https://github.com/Azure/api-management-samples)
- [Azure Feedback](https://feedback.azure.com/d365community/forum/1f1d9b2c-0425-ec11-b6e6-000d3a4f0858)

## Next Steps

- [Observability Guide](observability.md) - Set up comprehensive monitoring
- [Security Guide](security.md) - Debug authentication issues
- [Networking Guide](networking.md) - Troubleshoot connectivity

---

**When in doubt, check the logs!** Most issues leave traces in Application Insights or Log Analytics.
