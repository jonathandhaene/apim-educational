import { sendSMS } from './sendSMS';
import { HttpRequest, InvocationContext } from '@azure/functions';

// Mock Twilio
jest.mock('twilio', () => {
    return jest.fn(() => ({
        messages: {
            create: jest.fn().mockResolvedValue({
                sid: 'SM1234567890abcdef1234567890abcdef',
                status: 'queued'
            })
        }
    }));
});

describe('sendSMS Function', () => {
    let mockContext: InvocationContext;
    
    beforeEach(() => {
        // Set up environment variables
        process.env.TWILIO_ACCOUNT_SID = 'ACtest123';
        process.env.TWILIO_AUTH_TOKEN = 'test_token';
        process.env.TWILIO_FROM_NUMBER = '+15551234567';
        
        // Mock context
        mockContext = {
            log: jest.fn(),
            error: jest.fn()
        } as any;
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('should send SMS successfully', async () => {
        const request = {
            url: 'http://localhost:7071/api/sendSMS',
            json: jest.fn().mockResolvedValue({
                to: '+15559876543',
                message: 'Test message'
            })
        } as unknown as HttpRequest;

        const response = await sendSMS(request, mockContext);

        expect(response.status).toBe(200);
        expect(response.jsonBody).toHaveProperty('success', true);
        expect(response.jsonBody).toHaveProperty('messageSid');
    });

    it('should return 400 for missing fields', async () => {
        const request = {
            url: 'http://localhost:7071/api/sendSMS',
            json: jest.fn().mockResolvedValue({
                to: '+15559876543'
                // missing message
            })
        } as unknown as HttpRequest;

        const response = await sendSMS(request, mockContext);

        expect(response.status).toBe(400);
        expect(response.jsonBody).toHaveProperty('error');
    });

    it('should return 400 for invalid phone number', async () => {
        const request = {
            url: 'http://localhost:7071/api/sendSMS',
            json: jest.fn().mockResolvedValue({
                to: 'invalid-number',
                message: 'Test message'
            })
        } as unknown as HttpRequest;

        const response = await sendSMS(request, mockContext);

        expect(response.status).toBe(400);
        expect(response.jsonBody).toHaveProperty('error');
    });

    it('should return 500 when Twilio credentials are missing', async () => {
        delete process.env.TWILIO_ACCOUNT_SID;
        
        const request = {
            url: 'http://localhost:7071/api/sendSMS',
            json: jest.fn().mockResolvedValue({
                to: '+15559876543',
                message: 'Test message'
            })
        } as unknown as HttpRequest;

        const response = await sendSMS(request, mockContext);

        expect(response.status).toBe(500);
        expect(response.jsonBody).toHaveProperty('error');
    });
});
