import { useState } from 'react'
import './index.css'

interface ApiResponse {
  message: string;
  timestamp: string;
  functionName: string;
  version: string;
}

function App() {
  const [name, setName] = useState('React User')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [response, setResponse] = useState<ApiResponse | null>(null)
  const [apiUrl, setApiUrl] = useState('http://localhost:7071')
  const [subscriptionKey, setSubscriptionKey] = useState('')

  const callApi = async () => {
    setLoading(true)
    setError(null)
    setResponse(null)

    try {
      const headers: HeadersInit = {
        'Content-Type': 'application/json',
      }

      // Add subscription key if provided (for APIM)
      if (subscriptionKey) {
        headers['Ocp-Apim-Subscription-Key'] = subscriptionKey
      }

      const url = `${apiUrl}/api/httpTrigger?name=${encodeURIComponent(name)}`
      
      const res = await fetch(url, {
        method: 'GET',
        headers,
      })

      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`)
      }

      const data = await res.json()
      setResponse(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  const callApiPost = async () => {
    setLoading(true)
    setError(null)
    setResponse(null)

    try {
      const headers: HeadersInit = {
        'Content-Type': 'text/plain',
      }

      // Add subscription key if provided (for APIM)
      if (subscriptionKey) {
        headers['Ocp-Apim-Subscription-Key'] = subscriptionKey
      }

      const url = `${apiUrl}/api/httpTrigger`
      
      const res = await fetch(url, {
        method: 'POST',
        headers,
        body: name,
      })

      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`)
      }

      const data = await res.json()
      setResponse(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h1>Azure APIM React Sample</h1>
      <p>Demonstrating integration with Azure Functions via APIM</p>

      <div className="card">
        <h2>Configuration</h2>
        <div className="input-group">
          <label>
            API URL:
            <input
              type="text"
              value={apiUrl}
              onChange={(e) => setApiUrl(e.target.value)}
              placeholder="http://localhost:7071 or https://your-apim.azure-api.net"
              style={{ width: '100%', marginTop: '0.5em' }}
            />
          </label>
        </div>
        <div className="input-group">
          <label>
            Subscription Key (optional for APIM):
            <input
              type="password"
              value={subscriptionKey}
              onChange={(e) => setSubscriptionKey(e.target.value)}
              placeholder="Your APIM subscription key"
              style={{ width: '100%', marginTop: '0.5em' }}
            />
          </label>
        </div>
      </div>

      <div className="card">
        <h2>API Call</h2>
        <div className="input-group">
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter a name"
          />
        </div>
        <button onClick={callApi} disabled={loading}>
          {loading ? 'Loading...' : 'Call API (GET)'}
        </button>
        <button onClick={callApiPost} disabled={loading} style={{ marginLeft: '0.5em' }}>
          {loading ? 'Loading...' : 'Call API (POST)'}
        </button>
      </div>

      {error && (
        <div className="error">
          <strong>Error:</strong> {error}
        </div>
      )}

      {response && (
        <div className="success">
          <strong>Success!</strong>
          <div className="response">
            <pre>{JSON.stringify(response, null, 2)}</pre>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
