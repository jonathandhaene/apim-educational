# Frontend Integration Samples

This directory contains sample frontend applications demonstrating how to integrate with Azure Functions through Azure API Management (APIM).

## Available Samples

### [React Sample](react-sample/)

A modern React application built with Vite and TypeScript, demonstrating:
- Fetch API for HTTP requests
- APIM subscription key authentication
- Error handling and loading states
- Unit tests with Vitest
- Responsive UI with dark mode support

**Quick Start:**
```bash
cd react-sample
npm install
npm run dev
```

### [Angular Sample](angular-sample/)

An Angular 17 application demonstrating:
- HttpClient service for API integration
- Service pattern for API calls
- RxJS Observables for async operations
- Unit tests with Jasmine and Karma
- Responsive UI with dark mode support

**Quick Start:**
```bash
cd angular-sample
npm install
npm start
```

## Common Features

Both samples include:

✅ **APIM Integration**: Support for subscription key authentication  
✅ **Local Development**: Proxy configuration for CORS  
✅ **Error Handling**: Comprehensive error handling  
✅ **TypeScript**: Full type safety  
✅ **Testing**: Unit tests included  
✅ **Documentation**: Detailed README with deployment instructions

## Prerequisites

- Node.js 18.x or later
- Azure Function running locally or deployed
- Optional: Azure API Management instance

## Integration Flow

```
Frontend App → APIM Gateway → Azure Function → Backend Services
```

### Local Development

1. Start Azure Function:
```bash
cd ../../src/functions-sample
npm install
npm start
```

2. Start Frontend (in separate terminal):
```bash
cd frontend-samples/react-sample  # or angular-sample
npm install
npm run dev  # or npm start for Angular
```

3. Open browser to `http://localhost:3000` (React) or `http://localhost:4200` (Angular)

### Production with APIM

1. Deploy Azure Function to Azure
2. Import Function into APIM
3. Get APIM subscription key
4. Update frontend configuration:
   - Set API URL to APIM gateway URL
   - Add subscription key

## APIM Configuration

### CORS Policy

Add to your APIM API:

```xml
<cors allow-credentials="false">
  <allowed-origins>
    <origin>https://your-frontend-domain.com</origin>
    <origin>http://localhost:3000</origin>
    <origin>http://localhost:4200</origin>
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

### Rate Limiting

```xml
<rate-limit calls="1000" renewal-period="60" />
<quota calls="100000" renewal-period="2592000" />
```

## Deployment Options

### Azure Static Web Apps

```bash
az staticwebapp create \
  --name my-frontend \
  --resource-group my-rg \
  --source . \
  --location eastus \
  --branch main \
  --app-location "/" \
  --output-location "dist"
```

### Azure Storage (Static Website)

```bash
az storage account create --name mystorage --resource-group my-rg --sku Standard_LRS
az storage blob service-properties update --account-name mystorage --static-website \
  --index-document index.html --404-document index.html
az storage blob upload-batch --account-name mystorage --source ./dist --destination '$web'
```

### Azure App Service

```bash
az webapp create --name my-frontend --resource-group my-rg --plan my-plan --runtime "NODE|18-lts"
az webapp deployment source config-zip --name my-frontend --resource-group my-rg --src dist.zip
```

## Security Best Practices

### Development
- Use environment variables for configuration
- Add `.env` and `local.settings.json` to `.gitignore`
- Use proxy configuration to avoid CORS issues

### Production
- Enable HTTPS only
- Store subscription keys securely
- Use Azure Key Vault for secrets
- Implement Content Security Policy
- Enable Azure Front Door WAF
- Use managed identities where possible

## Testing

Both samples include unit tests:

**React:**
```bash
cd react-sample
npm test
```

**Angular:**
```bash
cd angular-sample
npm test
```

## Troubleshooting

### CORS Errors

**Local Development:**
- Verify proxy configuration in `vite.config.ts` or `proxy.conf.json`
- Ensure Azure Function is running

**Production:**
- Add CORS policy to APIM
- Verify allowed origins include your domain

### API Not Responding

- Check Azure Function logs
- Verify API URL is correct
- Check subscription key (if using APIM)
- Verify network connectivity

### Build Errors

- Delete `node_modules` and reinstall
- Ensure Node.js version is 18.x or later
- Clear build cache: `rm -rf dist node_modules`

## Learn More

- [React Documentation](https://react.dev/)
- [Angular Documentation](https://angular.io/)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Azure API Management](https://learn.microsoft.com/azure/api-management/)
- [Azure Static Web Apps](https://learn.microsoft.com/azure/static-web-apps/)

## Contributing

When adding new frontend samples:

1. Create a new directory under `frontend-samples/`
2. Include a comprehensive README
3. Add unit tests
4. Follow existing patterns for consistency
5. Document deployment options

## License

These samples are part of the Azure APIM Educational Repository.
