# Angular Sample - Azure APIM Integration

This sample Angular application demonstrates how to integrate with Azure Functions through Azure API Management (APIM) using Angular's HttpClient service.

## Features

- **HttpClient Service**: Uses Angular's built-in HttpClient for API calls
- **APIM Support**: Includes subscription key configuration for APIM gateway
- **TypeScript**: Full TypeScript support with strong typing
- **Service Pattern**: Demonstrates Angular service pattern for API integration
- **Unit Tests**: Comprehensive tests using Jasmine and Karma
- **Reactive Programming**: Uses RxJS Observables for asynchronous operations
- **Responsive UI**: Clean, modern interface with dark mode support

## Prerequisites

- [Node.js](https://nodejs.org/) 18.x or later
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- [Angular CLI](https://angular.io/cli) 17.x or later
- Azure Function running locally or deployed (see `../../src/functions-sample/`)

## Quick Start

### 1. Install Angular CLI (if not already installed)

```bash
npm install -g @angular/cli
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Start the Development Server

```bash
npm start
```

The app will be available at `http://localhost:4200`

### 4. Run the Azure Function

In a separate terminal, start the Azure Function:

```bash
cd ../../src/functions-sample
npm install
npm start
```

The function will be available at `http://localhost:7071`

### 5. Test the Integration

1. Open `http://localhost:4200` in your browser
2. Enter a name in the input field
3. Click "Call API (GET)" or "Call API (POST)"
4. View the response from the Azure Function

## Configuration

### Local Development

By default, the app connects to `http://localhost:7071` for local Azure Function testing. The proxy configuration in `proxy.conf.json` handles CORS automatically.

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
angular-sample/
├── src/
│   ├── app/
│   │   ├── app.component.ts       # Main application component
│   │   ├── app.component.html     # Main template
│   │   ├── app.component.css      # Component styles
│   │   ├── app.component.spec.ts  # Component tests
│   │   ├── app.module.ts          # Application module
│   │   ├── apim.service.ts        # APIM integration service
│   │   └── apim.service.spec.ts   # Service tests
│   ├── index.html                 # HTML entry point
│   ├── main.ts                    # Application bootstrap
│   └── styles.css                 # Global styles
├── angular.json                   # Angular CLI configuration
├── package.json                   # Dependencies and scripts
├── proxy.conf.json                # Development proxy configuration
├── tsconfig.json                  # TypeScript configuration
└── README.md                     # This file
```

## Available Scripts

### `npm start`

Starts the development server with hot reload at `http://localhost:4200`.

### `npm run build`

Builds the app for production to the `dist` folder.

### `npm test`

Runs the test suite using Karma and Jasmine.

### `npm run lint`

Lints the codebase (requires ESLint configuration).

## API Integration Details

### ApimService

The `ApimService` provides a clean abstraction for API calls:

```typescript
@Injectable({
  providedIn: 'root'
})
export class ApimService {
  constructor(private http: HttpClient) { }

  callApiGet(apiUrl: string, name: string, subscriptionKey?: string): Observable<ApiResponse> {
    const headers = this.buildHeaders(subscriptionKey);
    const url = `${apiUrl}/api/httpTrigger?name=${encodeURIComponent(name)}`;
    return this.http.get<ApiResponse>(url, { headers });
  }

  callApiPost(apiUrl: string, name: string, subscriptionKey?: string): Observable<ApiResponse> {
    const headers = this.buildHeaders(subscriptionKey, 'text/plain');
    const url = `${apiUrl}/api/httpTrigger`;
    return this.http.post<ApiResponse>(url, name, { headers });
  }

  private buildHeaders(subscriptionKey?: string, contentType: string = 'application/json'): HttpHeaders {
    let headers = new HttpHeaders({
      'Content-Type': contentType
    });

    if (subscriptionKey) {
      headers = headers.set('Ocp-Apim-Subscription-Key', subscriptionKey);
    }

    return headers;
  }
}
```

### Using the Service

In your component:

```typescript
export class AppComponent {
  constructor(private apimService: ApimService) { }

  callApiGet(): void {
    this.apimService.callApiGet(this.apiUrl, this.name, this.subscriptionKey)
      .subscribe({
        next: (data) => {
          this.response = data;
        },
        error: (err) => {
          this.error = err.message;
        }
      });
  }
}
```

## Testing

The app includes comprehensive unit tests using Jasmine and Karma.

### Run Tests

```bash
npm test
```

### Test Coverage

Tests cover:
- Service creation and methods
- HTTP requests (GET and POST)
- Subscription key headers
- Component initialization
- Error handling

### Example Test

```typescript
it('should call API with GET method', () => {
  const mockResponse: ApiResponse = {
    message: 'Hello, Test!',
    timestamp: '2024-01-01T00:00:00Z',
    functionName: 'sample-api-function',
    version: '1.0.0'
  };

  service.callApiGet(apiUrl, 'Test').subscribe(response => {
    expect(response).toEqual(mockResponse);
  });

  const req = httpMock.expectOne(`${apiUrl}/api/httpTrigger?name=Test`);
  expect(req.request.method).toBe('GET');
  req.flush(mockResponse);
});
```

## CORS Configuration

### Local Development

The app uses Angular CLI's proxy configuration to avoid CORS issues:

```json
{
  "/api": {
    "target": "http://localhost:7071",
    "secure": false,
    "changeOrigin": true
  }
}
```

### Production with APIM

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

This creates an optimized production build in the `dist/apim-angular-sample` folder.

### Deploy to Azure Static Web Apps

```bash
# Install Azure Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# Login to Azure
az login

# Deploy
az staticwebapp create \
  --name my-angular-apim-sample \
  --resource-group my-resource-group \
  --source . \
  --location eastus \
  --branch main \
  --app-location "/" \
  --output-location "dist/apim-angular-sample"
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
  --source ./dist/apim-angular-sample \
  --destination '$web'
```

## Environment Configuration

Angular supports environment files for different configurations:

### Create Environment Files

```typescript
// src/environments/environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:7071',
  subscriptionKey: ''
};

// src/environments/environment.prod.ts (production)
export const environment = {
  production: true,
  apiUrl: 'https://your-apim.azure-api.net',
  subscriptionKey: 'your-subscription-key'
};
```

### Use in Component

```typescript
import { environment } from '../environments/environment';

export class AppComponent {
  apiUrl = environment.apiUrl;
  subscriptionKey = environment.subscriptionKey;
}
```

## Troubleshooting

### CORS Errors

If you see CORS errors:
1. Ensure the Azure Function has CORS enabled for your frontend URL
2. For local development, verify `proxy.conf.json` is configured correctly
3. For APIM, add CORS policy to your API

### API Not Responding

1. Check that the Azure Function is running
2. Verify the API URL is correct
3. Open browser DevTools console for detailed error messages
4. Verify subscription key if using APIM

### Build Errors

If you encounter build errors:
1. Delete `node_modules` and `package-lock.json`
2. Run `npm install` again
3. Ensure you're using Node.js 18.x or later
4. Ensure Angular CLI is installed globally

### Test Failures

If tests fail:
1. Ensure all dependencies are installed
2. Check that Chrome is installed (required for Karma)
3. Run tests with `--watch=false` flag for single run

## Best Practices

### Error Handling

Always handle API errors gracefully using RxJS operators:

```typescript
this.apimService.callApiGet(url, name, key)
  .pipe(
    catchError(error => {
      console.error('API call failed:', error);
      return of(null);
    })
  )
  .subscribe(response => {
    // Handle response
  });
```

### Loading States

Show loading indicators during API calls:

```typescript
this.loading = true;
this.apimService.callApiGet(url, name, key)
  .pipe(
    finalize(() => this.loading = false)
  )
  .subscribe(response => {
    // Handle response
  });
```

### Unsubscribe from Observables

Always unsubscribe from observables to prevent memory leaks:

```typescript
private subscription: Subscription;

ngOnInit() {
  this.subscription = this.apimService.callApiGet(...)
    .subscribe(...);
}

ngOnDestroy() {
  if (this.subscription) {
    this.subscription.unsubscribe();
  }
}
```

Or use the `async` pipe in templates for automatic subscription management:

```html
<div *ngIf="response$ | async as response">
  {{ response.message }}
</div>
```

### Security

1. **Never commit subscription keys** - Use environment files and `.gitignore`
2. **Validate input** - Use Angular forms with validators
3. **Use HTTPS** - Always use HTTPS in production
4. **Implement rate limiting** - Prevent abuse of your API
5. **Sanitize output** - Angular's built-in sanitization helps prevent XSS

## Learn More

- [Angular Documentation](https://angular.io/docs)
- [RxJS Documentation](https://rxjs.dev/)
- [Angular HttpClient](https://angular.io/guide/http)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Azure API Management](https://learn.microsoft.com/azure/api-management/)
- [Azure Static Web Apps](https://learn.microsoft.com/azure/static-web-apps/)

## License

This sample is part of the Azure APIM Educational Repository and follows the same license.
