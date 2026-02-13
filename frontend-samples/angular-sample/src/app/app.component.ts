import { Component } from '@angular/core';
import { ApimService, ApiResponse } from './apim.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'Azure APIM Angular Sample';
  name = 'Angular User';
  apiUrl = 'http://localhost:7071';
  subscriptionKey = '';
  loading = false;
  error: string | null = null;
  response: ApiResponse | null = null;

  constructor(private apimService: ApimService) { }

  callApiGet(): void {
    this.loading = true;
    this.error = null;
    this.response = null;

    this.apimService.callApiGet(this.apiUrl, this.name, this.subscriptionKey || undefined)
      .subscribe({
        next: (data) => {
          this.response = data;
          this.loading = false;
        },
        error: (err) => {
          this.error = err.message || 'An error occurred';
          this.loading = false;
        }
      });
  }

  callApiPost(): void {
    this.loading = true;
    this.error = null;
    this.response = null;

    this.apimService.callApiPost(this.apiUrl, this.name, this.subscriptionKey || undefined)
      .subscribe({
        next: (data) => {
          this.response = data;
          this.loading = false;
        },
        error: (err) => {
          this.error = err.message || 'An error occurred';
          this.loading = false;
        }
      });
  }

  formatResponse(): string {
    return JSON.stringify(this.response, null, 2);
  }
}
