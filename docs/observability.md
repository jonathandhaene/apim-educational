# Azure API Management Observability Guide

Comprehensive monitoring, diagnostics, and analytics for Azure API Management.

## Table of Contents
- [Monitoring Strategy](#monitoring-strategy)
- [Application Insights Integration](#application-insights-integration)
- [Log Analytics](#log-analytics)
- [Metrics and Alerts](#metrics-and-alerts)
- [Custom Logging](#custom-logging)
- [Performance Troubleshooting](#performance-troubleshooting)

## Monitoring Strategy

### Three Pillars of Observability

1. **Metrics**: Numerical data over time (requests/sec, latency, errors)
2. **Logs**: Structured event data (request logs, errors, traces)
3. **Traces**: Distributed transaction tracking across services

### Monitoring Layers

```
┌─────────────────────────────────────┐
│  Business Metrics                   │  (API usage, revenue, user activity)
├─────────────────────────────────────┤
│  Application Metrics                │  (Response time, error rates, throughput)
├─────────────────────────────────────┤
│  Infrastructure Metrics             │  (CPU, memory, network, capacity)
├─────────────────────────────────────┤
│  Platform Logs                      │  (Gateway logs, diagnostic logs)
└─────────────────────────────────────┘
```

## Application Insights Integration

### Setup

**Bicep Configuration:**
```bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-apim'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  parent: apim
  name: 'app-insights-logger'
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
    isBuffered: true
    resourceId: appInsights.id
  }
}

resource apiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2023-05-01-preview' = {
  parent: api
  name: 'applicationinsights'
  properties: {
    loggerId: apimLogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: ['Content-Type', 'User-Agent']
        body: { bytes: 512 }
      }
      response: {
        headers: ['Content-Type']
        body: { bytes: 512 }
      }
    }
    backend: {
      request: {
        headers: ['Content-Type']
        body: { bytes: 512 }
      }
      response: {
        headers: ['Content-Type']
        body: { bytes: 512 }
      }
    }
  }
}
```

### Query Examples

**Request Volume Over Time:**
```kusto
requests
| where timestamp > ago(24h)
| summarize RequestCount = count() by bin(timestamp, 1h)
| render timechart
```

**Top Slowest Operations:**
```kusto
requests
| where timestamp > ago(24h)
| summarize AvgDuration = avg(duration), Count = count() by operation_Name
| order by AvgDuration desc
| take 10
```

**Error Rate:**
```kusto
requests
| where timestamp > ago(24h)
| summarize Total = count(), Errors = countif(success == false)
| extend ErrorRate = todouble(Errors) / Total * 100
```

**Failed Requests with Details:**
```kusto
requests
| where timestamp > ago(1h) and success == false
| project timestamp, name, resultCode, duration, operation_Name, cloud_RoleName
| order by timestamp desc
```

## Log Analytics

### Enable Diagnostic Settings

```bicep
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'apim-diagnostics'
  scope: apim
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}
```

### Log Categories

- **GatewayLogs**: All API requests/responses
- **WebSocketConnectionLogs**: WebSocket connections
- **AllMetrics**: Performance metrics

### Query Examples

**Gateway Logs - Failed Requests:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ResponseCode >= 400
| project TimeGenerated, ApiId, OperationId, Method, Url, ResponseCode, BackendResponseCode, ClientIp
| order by TimeGenerated desc
```

**Response Time Analysis:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| summarize AvgLatency = avg(TotalTime), P50 = percentile(TotalTime, 50), P95 = percentile(TotalTime, 95), P99 = percentile(TotalTime, 99) by ApiId
| order by P99 desc
```

**Top APIs by Traffic:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| summarize Count = count() by ApiId
| order by Count desc
| take 10
```

**Error Distribution:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| where ResponseCode >= 400
| summarize Count = count() by ResponseCode
| render piechart
```

## Metrics and Alerts

### Key Metrics

**Gateway Metrics:**
- **Requests**: Total number of API requests
- **Capacity**: Current capacity utilization (%)
- **Duration**: Request duration (ms)
- **Failed Requests**: Requests with 4xx or 5xx status
- **Successful Requests**: Requests with 2xx status

**Infrastructure Metrics:**
- **CPU**: CPU usage percentage
- **Memory**: Memory usage
- **Network**: Bytes sent/received

### Alert Rules

**High Error Rate:**
```bicep
resource errorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'apim-high-error-rate'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    scopes: [apim.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailedRequests'
          metricName: 'FailedRequests'
          operator: 'GreaterThan'
          threshold: 100
          timeAggregation: 'Total'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
```

**High Capacity Utilization:**
```bicep
resource capacityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'apim-high-capacity'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    scopes: [apim.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Capacity'
          metricName: 'Capacity'
          operator: 'GreaterThan'
          threshold: 70
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
```

### Recommended Alerts

| Alert | Metric | Threshold | Action |
|-------|--------|-----------|--------|
| High error rate | FailedRequests | >5% of total | Investigate immediately |
| High latency | Duration P95 | >2000ms | Check backend performance |
| Capacity warning | Capacity | >70% | Plan to scale |
| Capacity critical | Capacity | >90% | Scale immediately |
| Backend timeout | BackendTime | >10s | Check backend health |
| Auth failures | 401 responses | >10/min | Possible attack |

## Custom Logging

### Log Custom Data in Policies

**Log to Application Insights:**
```xml
<policies>
  <inbound>
    <trace source="custom-trace" severity="information">
      <message>@($"User {context.Request.Headers.GetValueOrDefault("X-User-Id", "anonymous")} accessed {context.Api.Name}")</message>
      <metadata name="userId" value="@(context.Request.Headers.GetValueOrDefault("X-User-Id", "anonymous"))" />
      <metadata name="apiName" value="@(context.Api.Name)" />
      <metadata name="operationName" value="@(context.Operation.Name)" />
    </trace>
  </inbound>
</policies>
```

**Log Response Time:**
```xml
<policies>
  <inbound>
    <set-variable name="startTime" value="@(DateTime.UtcNow)" />
  </inbound>
  <outbound>
    <set-variable name="endTime" value="@(DateTime.UtcNow)" />
    <trace source="timing" severity="information">
      <message>@($"Request took {((DateTime)context.Variables["endTime"] - (DateTime)context.Variables["startTime"]).TotalMilliseconds}ms")</message>
      <metadata name="durationMs" value="@(((DateTime)context.Variables["endTime"] - (DateTime)context.Variables["startTime"]).TotalMilliseconds.ToString())" />
    </trace>
  </outbound>
</policies>
```

**Log Business Events:**
```xml
<policies>
  <outbound>
    <choose>
      <when condition="@(context.Response.StatusCode == 201)">
        <trace source="business-event" severity="information">
          <message>New resource created</message>
          <metadata name="event" value="resource_created" />
          <metadata name="resourceType" value="@(context.Api.Name)" />
          <metadata name="userId" value="@(context.Request.Headers.GetValueOrDefault("X-User-Id", ""))" />
        </trace>
      </when>
    </choose>
  </outbound>
</policies>
```

## Performance Troubleshooting

### Identify Performance Bottlenecks

**Total Request Time Breakdown:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| extend BackendPct = (BackendTime / TotalTime) * 100
| extend ApimPct = ((TotalTime - BackendTime) / TotalTime) * 100
| summarize 
    AvgTotal = avg(TotalTime),
    AvgBackend = avg(BackendTime),
    AvgApim = avg(TotalTime - BackendTime),
    AvgBackendPct = avg(BackendPct)
  by ApiId
| order by AvgTotal desc
```

**Slow Backends:**
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| summarize P95Backend = percentile(BackendTime, 95), Count = count() by BackendId
| where P95Backend > 1000
| order by P95Backend desc
```

### Common Performance Issues

**1. High Backend Latency**
- **Symptom**: `BackendTime` high relative to `TotalTime`
- **Solutions**:
  - Optimize backend queries/code
  - Add backend caching
  - Scale backend service
  - Use CDN for static content

**2. Policy Overhead**
- **Symptom**: `TotalTime - BackendTime` is significant
- **Solutions**:
  - Simplify policies
  - Reduce external service calls in policies
  - Cache policy results
  - Optimize transformations

**3. Capacity Saturation**
- **Symptom**: Capacity metric >80%, increased latency
- **Solutions**:
  - Scale out (add units)
  - Implement caching
  - Optimize policies
  - Rate limit clients

**4. Network Latency**
- **Symptom**: High latency from specific regions
- **Solutions**:
  - Deploy multi-region (Premium tier)
  - Use Azure Front Door
  - Implement response caching

### Diagnostic Tools

**Test Connectivity:**
```bash
# Test from Azure Cloud Shell or VM in same region
curl -w "@curl-format.txt" -o /dev/null -s "https://apim-instance.azure-api.net/api/endpoint"

# curl-format.txt
time_namelookup:  %{time_namelookup}\n
time_connect:  %{time_connect}\n
time_appconnect:  %{time_appconnect}\n
time_pretransfer:  %{time_pretransfer}\n
time_redirect:  %{time_redirect}\n
time_starttransfer:  %{time_starttransfer}\n
time_total:  %{time_total}\n
```

**Check APIM Status:**
```bash
az apim show --name apim-instance --resource-group rg-apim --query "provisioningState"
```

**View Metrics:**
```bash
az monitor metrics list \
  --resource /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ApiManagement/service/{apim} \
  --metric Requests,Capacity,Duration \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --interval PT1H
```

## Best Practices

### Monitoring

1. **Enable All Diagnostics**: Gateway logs, metrics, Application Insights
2. **Set Retention Policies**: Balance cost and compliance needs
3. **Use Sampling Wisely**: 100% for critical APIs, lower for high-volume
4. **Create Dashboards**: Centralized view of key metrics
5. **Document Baselines**: Know normal behavior to detect anomalies

### Alerting

1. **Alert on Symptoms**: Focus on user impact (errors, latency) not causes (CPU)
2. **Set Appropriate Thresholds**: Avoid alert fatigue
3. **Use Action Groups**: Route to correct teams (on-call, Slack, email)
4. **Test Alerts**: Verify alerts fire correctly
5. **Document Runbooks**: What to do when alert fires

### Logging

1. **Log Selectively**: Don't log sensitive data (passwords, tokens)
2. **Use Structured Logging**: JSON format for easier querying
3. **Include Context**: Request ID, user ID, correlation ID
4. **Monitor Log Costs**: Application Insights can be expensive at scale
5. **Implement Log Rotation**: Set retention policies

### Performance

1. **Monitor Capacity**: Scale before hitting 80%
2. **Optimize Policies**: Profile policy execution time
3. **Use Caching**: Response caching and external cache
4. **Monitor Backend**: APIM is only as fast as backends
5. **Test at Scale**: Load testing reveals bottlenecks

## Dashboards

### Example Azure Dashboard (JSON)

Key widgets to include:
- **Request Volume**: Line chart over time
- **Error Rate**: Percentage of failed requests
- **Latency**: P50, P95, P99 over time
- **Capacity**: Current utilization
- **Top APIs**: Table of most used APIs
- **Recent Errors**: List of recent failed requests

### Grafana Integration

Use Azure Monitor data source in Grafana for custom dashboards.

## Next Steps

- [Troubleshooting Guide](troubleshooting.md) - Debug common issues
- [Security Guide](security.md) - Audit and security monitoring
- [Tiers and SKUs](tiers-and-skus.md) - Capacity planning

---

**Monitor everything!** You can't optimize what you don't measure.
