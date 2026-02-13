import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuration
const GATEWAY_URL = __ENV.GATEWAY_URL || 'https://apim-dev.azure-api.net';
const SUBSCRIPTION_KEY = __ENV.SUBSCRIPTION_KEY || 'YOUR_KEY_HERE';
const API_PATH = '/sample/httpTrigger';

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users
    { duration: '1m', target: 10 },   // Stay at 10 users
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.01'],    // Error rate should be less than 1%
  },
};

export default function () {
  const url = `${GATEWAY_URL}${API_PATH}`;
  const params = {
    headers: {
      'Ocp-Apim-Subscription-Key': SUBSCRIPTION_KEY,
    },
  };

  // GET request
  const response = http.get(`${url}?name=k6`, params);

  // Assertions
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response has message': (r) => r.json('message') !== undefined,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
