# AI Gateway with Azure API Management

Guide for using Azure API Management as an AI Gateway to manage, secure, and monitor AI/LLM API consumption.

## Table of Contents
- [What is an AI Gateway?](#what-is-an-ai-gateway)
- [Why Use APIM for AI APIs?](#why-use-apim-for-ai-apis)
- [Azure OpenAI Integration](#azure-openai-integration)
- [Cost Management](#cost-management)
- [Rate Limiting and Quotas](#rate-limiting-and-quotas)
- [Load Balancing](#load-balancing)
- [Prompt Engineering](#prompt-engineering)

## What is an AI Gateway?

An AI Gateway acts as an intermediary between applications and AI/LLM services:

```
Application → AI Gateway (APIM) → AI Services
                                   ├─ Azure OpenAI
                                   ├─ OpenAI
                                   ├─ Anthropic
                                   └─ Other LLMs
```

**Key Functions:**
- **Cost Control**: Track and limit AI API spend
- **Rate Limiting**: Prevent quota exhaustion
- **Load Balancing**: Distribute across multiple endpoints
- **Monitoring**: Track token usage and costs
- **Security**: Protect API keys, implement authentication
- **Fallback**: Handle failures gracefully
- **Caching**: Cache responses to reduce costs
- **Content Filtering**: Enforce safety and compliance

## Why Use APIM for AI APIs?

### 1. Cost Management

AI APIs charge by token consumption:
- GPT-4: $0.03/1K input tokens, $0.06/1K output tokens
- GPT-3.5: $0.0015/1K input tokens, $0.002/1K output tokens
- Embeddings: $0.0001/1K tokens

**Uncontrolled usage** can quickly become expensive.

**APIM Solutions:**
- Quota enforcement per user/subscription
- Budget alerts based on token consumption
- Chargeback to business units
- Cost analytics and reporting

### 2. Security

**Challenges:**
- Exposing API keys in client applications
- Unauthorized access to expensive resources
- Prompt injection attacks

**APIM Solutions:**
- Hide backend API keys
- Implement OAuth/JWT authentication
- Content filtering policies
- IP whitelisting

### 3. Reliability

**Challenges:**
- Rate limit errors (429)
- Service availability (downtime)
- Regional capacity issues

**APIM Solutions:**
- Retry with exponential backoff
- Load balancing across multiple endpoints
- Failover to alternative providers
- Response caching

### 4. Observability

**Challenges:**
- Understanding usage patterns
- Tracking costs per user/team
- Identifying inefficient prompts

**APIM Solutions:**
- Detailed logging to Application Insights
- Token consumption metrics
- Custom analytics dashboards
- Alert on anomalies

## Azure OpenAI Integration

### Backend Configuration

**Multiple Azure OpenAI Instances:**
```bicep
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: 'apim-ai-gateway'
}

resource openAIBackend1 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apim
  name: 'aoai-eastus'
  properties: {
    protocol: 'http'
    url: 'https://aoai-eastus.openai.azure.com/openai'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 3
            errorReasons: ['Server errors']
            interval: 'PT5M'
            statusCodeRanges: [
              {
                min: 500
                max: 599
              }
            ]
          }
          tripDuration: 'PT1M'
        }
      ]
    }
  }
}

resource openAIBackend2 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apim
  name: 'aoai-westus'
  properties: {
    protocol: 'http'
    url: 'https://aoai-westus.openai.azure.com/openai'
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 3
            errorReasons: ['Server errors']
            interval: 'PT5M'
            statusCodeRanges: [
              {
                min: 500
                max: 599
              }
            ]
          }
          tripDuration: 'PT1M'
        }
      ]
    }
  }
}
```

### API Policy - Basic Integration

```xml
<policies>
  <inbound>
    <base />
    <!-- Authenticate using subscription key -->
    <check-header name="Ocp-Apim-Subscription-Key" failed-check-httpcode="401" />
    
    <!-- Use Managed Identity for Azure OpenAI authentication -->
    <authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="msi-access-token" />
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
    
    <!-- Remove client's API key if present -->
    <set-header name="api-key" exists-action="delete" />
    
    <!-- Add tracking headers -->
    <set-header name="X-User-Id" exists-action="override">
      <value>@(context.User?.Id ?? "anonymous")</value>
    </set-header>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
    <!-- Log token usage for billing -->
    <choose>
      <when condition="@(context.Response.StatusCode == 200)">
        <log-to-eventhub logger-id="eventhub-logger">
          @{
            var responseBody = context.Response.Body?.As<JObject>(preserveContent: true);
            return new JObject(
              new JProperty("timestamp", DateTime.UtcNow),
              new JProperty("userId", context.User?.Id ?? "anonymous"),
              new JProperty("model", context.Request.Url.Path.Split('/').Last()),
              new JProperty("promptTokens", responseBody?["usage"]?["prompt_tokens"]),
              new JProperty("completionTokens", responseBody?["usage"]?["completion_tokens"]),
              new JProperty("totalTokens", responseBody?["usage"]?["total_tokens"])
            ).ToString();
          }
        </log-to-eventhub>
      </when>
    </choose>
  </outbound>
</policies>
```

## Cost Management

### Track Token Usage

**Log to Event Hub for analysis:**
```xml
<policies>
  <outbound>
    <choose>
      <when condition="@(context.Response.StatusCode == 200)">
        <log-to-eventhub logger-id="ai-usage-logger">
          @{
            var responseBody = context.Response.Body?.As<JObject>(preserveContent: true);
            var usage = responseBody?["usage"];
            var model = context.Request.MatchedParameters["deployment-id"];
            
            // Calculate estimated cost (example rates)
            var promptTokens = (int?)usage?["prompt_tokens"] ?? 0;
            var completionTokens = (int?)usage?["completion_tokens"] ?? 0;
            
            // GPT-4 rates (per 1K tokens)
            var inputCostPer1K = 0.03;
            var outputCostPer1K = 0.06;
            var estimatedCost = (promptTokens / 1000.0 * inputCostPer1K) + 
                              (completionTokens / 1000.0 * outputCostPer1K);
            
            return new JObject(
              new JProperty("timestamp", DateTime.UtcNow),
              new JProperty("userId", context.User?.Id ?? context.Subscription?.Name ?? "anonymous"),
              new JProperty("subscriptionId", context.Subscription?.Id),
              new JProperty("model", model),
              new JProperty("promptTokens", promptTokens),
              new JProperty("completionTokens", completionTokens),
              new JProperty("totalTokens", (int?)usage?["total_tokens"] ?? 0),
              new JProperty("estimatedCost", estimatedCost)
            ).ToString();
          }
        </log-to-eventhub>
      </when>
    </choose>
  </outbound>
</policies>
```

**Query Total Cost per User:**
```kusto
// In Log Analytics after ingesting from Event Hub
AIUsageLogs
| where TimeGenerated > ago(30d)
| summarize TotalCost = sum(estimatedCost), TotalRequests = count() by userId
| order by TotalCost desc
```

### Enforce Budgets

**Per-user monthly quota:**
```xml
<policies>
  <inbound>
    <!-- Monthly token quota per user (e.g., 1 million tokens) -->
    <quota-by-key calls="1000000" renewal-period="2592000" counter-key="@($"tokens-{context.User?.Id}")" />
  </inbound>
</policies>
```

**Cost-based quota (requires external service):**
```xml
<policies>
  <inbound>
    <!-- Check user's monthly spend -->
    <send-request mode="new" response-variable-name="budgetCheck" timeout="5" ignore-error="false">
      <set-url>https://budget-service.example.com/check</set-url>
      <set-method>POST</set-method>
      <set-header name="Content-Type" exists-action="override">
        <value>application/json</value>
      </set-header>
      <set-body>@(new JObject(new JProperty("userId", context.User?.Id)).ToString())</set-body>
    </send-request>
    
    <choose>
      <when condition="@(((IResponse)context.Variables["budgetCheck"]).StatusCode != 200)">
        <return-response>
          <set-status code="429" reason="Budget Exceeded" />
          <set-body>Monthly AI budget exceeded. Please contact your administrator.</set-body>
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

## Rate Limiting and Quotas

### Protect Against TPM (Tokens Per Minute) Limits

Azure OpenAI has TPM limits (e.g., 120K TPM for GPT-4).

**Rate limit by tokens:**
```xml
<policies>
  <inbound>
    <!-- Estimate token count from prompt (rough estimate: 1 token ≈ 4 chars) -->
    <set-variable name="estimatedTokens" value="@{
      var body = context.Request.Body?.As<JObject>(preserveContent: true);
      var promptLength = body?["prompt"]?.ToString().Length ?? 0;
      var messagesLength = body?["messages"]?.ToString().Length ?? 0;
      var totalChars = promptLength + messagesLength;
      return (int)(totalChars / 4.0);
    }" />
    
    <!-- Rate limit: 100,000 tokens per minute per subscription -->
    <rate-limit-by-key calls="100000" renewal-period="60" 
                       counter-key="@(context.Subscription.Id)" 
                       increment-count="@((int)context.Variables["estimatedTokens"])" />
  </inbound>
</policies>
```

### Retry on Rate Limit (429)

```xml
<policies>
  <inbound>
    <retry condition="@(context.Response.StatusCode == 429)" count="3" interval="2" delta="2">
      <forward-request timeout="120" />
    </retry>
  </inbound>
</policies>
```

## Load Balancing

### Round-Robin Across Multiple Azure OpenAI Instances

```xml
<policies>
  <inbound>
    <set-variable name="backendIndex" value="@(new Random().Next(0, 2))" />
    <choose>
      <when condition="@((int)context.Variables["backendIndex"] == 0)">
        <set-backend-service backend-id="aoai-eastus" />
      </when>
      <when condition="@((int)context.Variables["backendIndex"] == 1)">
        <set-backend-service backend-id="aoai-westus" />
      </when>
    </choose>
  </inbound>
  <backend>
    <retry condition="@(context.Response.StatusCode == 429 || context.Response.StatusCode >= 500)" count="2" interval="1">
      <!-- Try alternate backend on failure -->
      <choose>
        <when condition="@((int)context.Variables["backendIndex"] == 0)">
          <set-backend-service backend-id="aoai-westus" />
        </when>
        <otherwise>
          <set-backend-service backend-id="aoai-eastus" />
        </otherwise>
      </choose>
      <forward-request timeout="120" />
    </retry>
  </backend>
</policies>
```

### Weighted Load Balancing

```xml
<policies>
  <inbound>
    <!-- 70% to primary, 30% to secondary -->
    <set-variable name="random" value="@(new Random().Next(0, 100))" />
    <choose>
      <when condition="@((int)context.Variables["random"] < 70)">
        <set-backend-service backend-id="aoai-primary" />
      </when>
      <otherwise>
        <set-backend-service backend-id="aoai-secondary" />
      </otherwise>
    </choose>
  </inbound>
</policies>
```

## Prompt Engineering

### Inject System Prompts

**Enforce guardrails:**
```xml
<policies>
  <inbound>
    <set-body>@{
      var body = context.Request.Body.As<JObject>(preserveContent: true);
      var messages = body["messages"] as JArray;
      
      // Inject system message if not present
      if (messages != null && !messages.Any(m => m["role"]?.ToString() == "system")) {
        messages.Insert(0, new JObject(
          new JProperty("role", "system"),
          new JProperty("content", "You are a helpful AI assistant. Do not provide information on harmful topics. If asked about sensitive information, politely decline.")
        ));
        body["messages"] = messages;
      }
      
      return body.ToString();
    }</set-body>
  </inbound>
</policies>
```

### Content Filtering

**Block sensitive prompts:**
```xml
<policies>
  <inbound>
    <set-variable name="prompt" value="@{
      var body = context.Request.Body.As<JObject>(preserveContent: true);
      return body?["prompt"]?.ToString() ?? 
             string.Join(" ", (body?["messages"] as JArray)?.Select(m => m["content"]?.ToString()) ?? new string[0]);
    }" />
    
    <!-- Check for prohibited content -->
    <choose>
      <when condition="@{
        var prompt = (string)context.Variables["prompt"];
        var blockedTerms = new[] { "hack", "exploit", "bypass", "illegal" };
        return blockedTerms.Any(term => prompt.ToLower().Contains(term));
      }">
        <return-response>
          <set-status code="400" reason="Prohibited Content" />
          <set-body>Your request contains prohibited content and cannot be processed.</set-body>
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### Response Caching

**Cache identical prompts:**
```xml
<policies>
  <inbound>
    <!-- Create cache key from prompt -->
    <set-variable name="cacheKey" value="@{
      var body = context.Request.Body.As<JObject>(preserveContent: true);
      var prompt = body?["prompt"]?.ToString() ?? body?["messages"]?.ToString();
      var model = context.Request.MatchedParameters["deployment-id"];
      return $"ai-cache-{model}-{prompt.GetHashCode()}";
    }" />
    
    <!-- Try to get from cache -->
    <cache-lookup-value key="@((string)context.Variables["cacheKey"])" variable-name="cachedResponse" />
    
    <choose>
      <when condition="@(context.Variables.ContainsKey("cachedResponse"))">
        <return-response>
          <set-status code="200" />
          <set-header name="X-Cache" exists-action="override">
            <value>HIT</value>
          </set-header>
          <set-body>@((string)context.Variables["cachedResponse"])</set-body>
        </return-response>
      </when>
    </choose>
  </inbound>
  <outbound>
    <!-- Cache successful responses for 1 hour -->
    <choose>
      <when condition="@(context.Response.StatusCode == 200)">
        <cache-store-value key="@((string)context.Variables["cacheKey"])" 
                          value="@(context.Response.Body.As<string>(preserveContent: true))" 
                          duration="3600" />
      </when>
    </choose>
  </outbound>
</policies>
```

## Advanced Patterns

### Semantic Caching

Cache based on semantic similarity (requires external service):
```xml
<policies>
  <inbound>
    <!-- Check semantic similarity with cached prompts -->
    <send-request mode="new" response-variable-name="similarPrompt" timeout="2" ignore-error="true">
      <set-url>https://semantic-cache.example.com/search</set-url>
      <set-method>POST</set-method>
      <set-body>@(context.Request.Body.As<string>(preserveContent: true))</set-body>
    </send-request>
    
    <!-- If similar prompt found (>95% similarity), return cached response -->
    <choose>
      <when condition="@{
        var response = context.Variables.ContainsKey("similarPrompt") ? 
                      (IResponse)context.Variables["similarPrompt"] : null;
        return response != null && response.StatusCode == 200;
      }">
        <return-response>
          <set-status code="200" />
          <set-header name="X-Cache" exists-action="override">
            <value>SEMANTIC-HIT</value>
          </set-header>
          <set-body>@{
            var response = (IResponse)context.Variables["similarPrompt"];
            return response.Body.As<string>();
          }</set-body>
        </return-response>
      </when>
    </choose>
  </inbound>
</policies>
```

### A/B Testing Models

```xml
<policies>
  <inbound>
    <!-- Route 10% of traffic to GPT-4, 90% to GPT-3.5 -->
    <set-variable name="modelChoice" value="@(new Random().Next(0, 100) < 10 ? "gpt-4" : "gpt-35-turbo")" />
    <set-url>@($"{context.Request.Url.Scheme}://{context.Request.Url.Host}/openai/deployments/{context.Variables["modelChoice"]}/chat/completions?api-version=2023-05-15")</set-url>
    
    <!-- Track which model was used -->
    <set-header name="X-Model-Used" exists-action="override">
      <value>@((string)context.Variables["modelChoice"])</value>
    </set-header>
  </inbound>
</policies>
```

## Best Practices

1. **Use Managed Identity**: Don't expose Azure OpenAI keys
2. **Implement Quotas**: Prevent runaway costs
3. **Log Token Usage**: Track consumption for chargeback
4. **Load Balance**: Distribute across multiple instances
5. **Cache Aggressively**: Reduce redundant API calls
6. **Retry with Backoff**: Handle rate limits gracefully
7. **Content Filtering**: Enforce safety and compliance
8. **Monitor Costs**: Set up alerts on spending thresholds
9. **Version Control Prompts**: Track prompt changes like code
10. **Test at Scale**: Validate performance under load

## Example Use Cases

### Enterprise Chatbot

- Multiple departments sharing Azure OpenAI
- APIM enforces quotas per department
- Centralizedlogging and cost allocation
- Content filtering for compliance

### Developer Productivity Tool

- Code generation assistant (GitHub Copilot alternative)
- Rate limiting per developer
- Cache common code patterns
- Track usage for licensing

### Customer Support

- AI-powered support chatbot
- Load balancing across regions for reliability
- A/B testing different models
- Response caching for FAQs

## Additional Resources

- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
- [APIM + Azure OpenAI Reference](https://learn.microsoft.com/azure/api-management/api-management-howto-use-azure-openai-service)
- [Token Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/)
- [Prompt Engineering Guide](https://learn.microsoft.com/azure/ai-services/openai/concepts/prompt-engineering)

## Next Steps

- [Security Guide](security.md) - Secure AI API access
- [Observability](observability.md) - Monitor AI usage
- [Cost Management](tiers-and-skus.md) - Optimize APIM costs

---

**AI is expensive.** Manage it like any other critical resource with governance, security, and observability.
