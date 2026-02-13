import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ApiResponse {
  message: string;
  timestamp: string;
  functionName: string;
  version: string;
}

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
