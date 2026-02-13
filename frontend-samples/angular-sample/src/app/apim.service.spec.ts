import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { ApimService, ApiResponse } from './apim.service';

describe('ApimService', () => {
  let service: ApimService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [ApimService]
    });
    service = TestBed.inject(ApimService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should call API with GET method', () => {
    const mockResponse: ApiResponse = {
      message: 'Hello, Test!',
      timestamp: '2024-01-01T00:00:00Z',
      functionName: 'sample-api-function',
      version: '1.0.0'
    };

    const apiUrl = 'http://localhost:7071';
    const name = 'Test';

    service.callApiGet(apiUrl, name).subscribe(response => {
      expect(response).toEqual(mockResponse);
    });

    const req = httpMock.expectOne(`${apiUrl}/api/httpTrigger?name=Test`);
    expect(req.request.method).toBe('GET');
    req.flush(mockResponse);
  });

  it('should call API with POST method', () => {
    const mockResponse: ApiResponse = {
      message: 'Hello, Test!',
      timestamp: '2024-01-01T00:00:00Z',
      functionName: 'sample-api-function',
      version: '1.0.0'
    };

    const apiUrl = 'http://localhost:7071';
    const name = 'Test';

    service.callApiPost(apiUrl, name).subscribe(response => {
      expect(response).toEqual(mockResponse);
    });

    const req = httpMock.expectOne(`${apiUrl}/api/httpTrigger`);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toBe(name);
    req.flush(mockResponse);
  });

  it('should include subscription key in headers when provided', () => {
    const mockResponse: ApiResponse = {
      message: 'Hello, Test!',
      timestamp: '2024-01-01T00:00:00Z',
      functionName: 'sample-api-function',
      version: '1.0.0'
    };

    const apiUrl = 'http://localhost:7071';
    const name = 'Test';
    const subscriptionKey = 'test-key-123';

    service.callApiGet(apiUrl, name, subscriptionKey).subscribe(response => {
      expect(response).toEqual(mockResponse);
    });

    const req = httpMock.expectOne(`${apiUrl}/api/httpTrigger?name=Test`);
    expect(req.request.headers.get('Ocp-Apim-Subscription-Key')).toBe(subscriptionKey);
    req.flush(mockResponse);
  });
});
