# React Sample - Azure APIM Integration

This sample React application demonstrates how to integrate with Azure Functions through Azure API Management (APIM).

## Features

- **Fetch API Integration**: Uses the native `fetch` API to call Azure Functions
- **APIM Support**: Includes subscription key configuration for APIM gateway
- **TypeScript**: Full TypeScript support for type safety
- **Vite**: Fast development experience with Vite
- **Unit Tests**: Comprehensive tests using Vitest and React Testing Library
- **Responsive UI**: Clean, modern interface with dark mode support

## Prerequisites

- [Node.js](https://nodejs.org/) 18.x or later
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- Azure Function running locally or deployed (see `../../src/functions-sample/`)

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Start the Development Server

```bash
npm run dev
```

The app will be available at `http://localhost:3000`

### 3. Run the Azure Function

In a separate terminal, start the Azure Function:

```bash
cd ../../src/functions-sample
npm install
npm start
```

The function will be available at `http://localhost:7071`

### 4. Test the Integration

1. Open `http://localhost:3000` in your browser
2. Enter a name in the input field
3. Click "Call API (GET)" or "Call API (POST)"
4. View the response from the Azure Function

## Configuration

### Local Development

By default, the app connects to `http://localhost:7071` for local Azure Function testing.

### Using Azure APIM

To connect to an Azure Function via APIM:

1. Update the API URL to your APIM gateway:
   ```
   https://your-apim.azure-api.net
   ```

2. Add your APIM subscription key in the "Subscription Key" field

3. Call the API as usual

## Project Structure

```
react-sample/
├── src/
│   ├── App.tsx           # Main application component
│   ├── App.test.tsx      # Tests for App component
│   ├── main.tsx          # Application entry point
│   └── index.css         # Global styles
├── index.html            # HTML template
├── package.json          # Dependencies and scripts
├── vite.config.ts        # Vite configuration
├── tsconfig.json         # TypeScript configuration
└── README.md            # This file
```

## Available Scripts

### `npm run dev`

Starts the development server with hot reload at `http://localhost:3000`.

### `npm run build`

Builds the app for production to the `dist` folder.

### `npm run preview`

Serves the production build locally for testing.

### `npm test`

Runs the test suite in watch mode.

## API Integration Details

The app demonstrates two types of HTTP requests:

### GET Request

```typescript
const response = await fetch(
  `${apiUrl}/api/httpTrigger?name=${encodeURIComponent(name)}`,
  {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Ocp-Apim-Subscription-Key': subscriptionKey, // if using APIM
    },
  }
)
```

### POST Request

```typescript
const response = await fetch(`${apiUrl}/api/httpTrigger`, {
  method: 'POST',
  headers: {
    'Content-Type': 'text/plain',
    'Ocp-Apim-Subscription-Key': subscriptionKey, // if using APIM
  },
  body: name,
})
```

## Testing

The app includes comprehensive unit tests using Vitest and React Testing Library.

### Run Tests

```bash
npm test
```

### Test Coverage

Tests cover:
- Component rendering
- User interactions
- API calls (mocked)
- Error handling
- Subscription key headers

### Example Test

```typescript
it('calls API on GET button click', async () => {
  const mockResponse = {
    message: 'Hello, Test User!',
    timestamp: '2024-01-01T00:00:00Z',
    functionName: 'sample-api-function',
    version: '1.0.0',
  }

  global.fetch = vi.fn().mockResolvedValueOnce({
    ok: true,
    json: async () => mockResponse,
  })

  render(<App />)
  
  const getButton = screen.getByText('Call API (GET)')
  fireEvent.click(getButton)

  await waitFor(() => {
    expect(screen.getByText('Success!')).toBeInTheDocument()
  })
})
```

## CORS Configuration

When running locally, the app uses Vite's proxy to avoid CORS issues:

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:7071',
        changeOrigin: true,
      },
    },
  },
})
```

For production deployment with APIM, ensure CORS is configured in your APIM policies:

```xml
<cors allow-credentials="false">
  <allowed-origins>
    <origin>https://your-frontend-domain.com</origin>
  </allowed-origins>
  <allowed-methods>
    <method>GET</method>
    <method>POST</method>
  </allowed-methods>
  <allowed-headers>
    <header>*</header>
  </allowed-headers>
</cors>
```

## Deployment

### Build for Production

```bash
npm run build
```

This creates an optimized production build in the `dist` folder.

### Deploy to Azure Static Web Apps

```bash
# Install Azure Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# Login to Azure
az login

# Deploy
az staticwebapp create \
  --name my-react-apim-sample \
  --resource-group my-resource-group \
  --source . \
  --location eastus \
  --branch main \
  --app-location "/" \
  --output-location "dist"
```

### Deploy to Azure Storage (Static Website)

```bash
# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group my-resource-group \
  --location eastus \
  --sku Standard_LRS

# Enable static website hosting
az storage blob service-properties update \
  --account-name mystorageaccount \
  --static-website \
  --index-document index.html \
  --404-document index.html

# Upload files
az storage blob upload-batch \
  --account-name mystorageaccount \
  --source ./dist \
  --destination '$web'
```

## Environment Variables

For production deployments, you can use environment variables:

Create a `.env` file:

```env
VITE_API_URL=https://your-apim.azure-api.net
VITE_SUBSCRIPTION_KEY=your-subscription-key
```

Access in code:

```typescript
const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:7071'
const subscriptionKey = import.meta.env.VITE_SUBSCRIPTION_KEY || ''
```

## Troubleshooting

### CORS Errors

If you see CORS errors:
1. Ensure the Azure Function has CORS enabled for your frontend URL
2. For local development, use the Vite proxy (already configured)
3. For APIM, add CORS policy to your API

### API Not Responding

1. Check that the Azure Function is running
2. Verify the API URL is correct
3. Check browser console for detailed error messages
4. Verify subscription key if using APIM

### Build Errors

If you encounter build errors:
1. Delete `node_modules` and `package-lock.json`
2. Run `npm install` again
3. Ensure you're using Node.js 18.x or later

## Best Practices

### Error Handling

Always handle API errors gracefully:

```typescript
try {
  const response = await fetch(url, options)
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }
  const data = await response.json()
  // Handle success
} catch (error) {
  // Handle error
  console.error('API call failed:', error)
}
```

### Loading States

Show loading indicators during API calls:

```typescript
const [loading, setLoading] = useState(false)

const callApi = async () => {
  setLoading(true)
  try {
    // API call
  } finally {
    setLoading(false)
  }
}
```

### Security

1. **Never commit subscription keys** - Use environment variables
2. **Validate input** - Sanitize user input before sending to API
3. **Use HTTPS** - Always use HTTPS in production
4. **Implement rate limiting** - Prevent abuse of your API

## Learn More

- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Azure API Management](https://learn.microsoft.com/azure/api-management/)
- [Azure Static Web Apps](https://learn.microsoft.com/azure/static-web-apps/)

## License

This sample is part of the Azure APIM Educational Repository and follows the same license.
