import { processPayment } from './processPayment';
import { HttpRequest, InvocationContext } from '@azure/functions';

// Mock Stripe
jest.mock('stripe', () => {
    return jest.fn().mockImplementation(() => ({
        paymentIntents: {
            create: jest.fn().mockResolvedValue({
                id: 'pi_1234567890',
                status: 'succeeded',
                amount: 1000,
                currency: 'usd',
                created: 1234567890
            })
        }
    }));
});

describe('processPayment Function', () => {
    let mockContext: InvocationContext;
    
    beforeEach(() => {
        // Set up environment variables
        process.env.STRIPE_SECRET_KEY = 'sk_test_1234567890';
        
        // Mock context
        mockContext = {
            log: jest.fn(),
            error: jest.fn()
        } as any;
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('should process payment successfully', async () => {
        const request = {
            url: 'http://localhost:7071/api/processPayment',
            json: jest.fn().mockResolvedValue({
                amount: 1000,
                currency: 'USD',
                paymentMethodId: 'pm_test_123',
                description: 'Test payment'
            })
        } as unknown as HttpRequest;

        const response = await processPayment(request, mockContext);

        expect(response.status).toBe(200);
        expect(response.jsonBody).toHaveProperty('success', true);
        expect(response.jsonBody).toHaveProperty('paymentIntentId');
    });

    it('should return 400 for missing fields', async () => {
        const request = {
            url: 'http://localhost:7071/api/processPayment',
            json: jest.fn().mockResolvedValue({
                amount: 1000,
                currency: 'USD'
                // missing paymentMethodId
            })
        } as unknown as HttpRequest;

        const response = await processPayment(request, mockContext);

        expect(response.status).toBe(400);
        expect(response.jsonBody).toHaveProperty('error');
    });

    it('should return 400 for invalid amount', async () => {
        const request = {
            url: 'http://localhost:7071/api/processPayment',
            json: jest.fn().mockResolvedValue({
                amount: -100,
                currency: 'USD',
                paymentMethodId: 'pm_test_123'
            })
        } as unknown as HttpRequest;

        const response = await processPayment(request, mockContext);

        expect(response.status).toBe(400);
        expect(response.jsonBody).toHaveProperty('error');
    });

    it('should return 400 for invalid currency', async () => {
        const request = {
            url: 'http://localhost:7071/api/processPayment',
            json: jest.fn().mockResolvedValue({
                amount: 1000,
                currency: 'INVALID',
                paymentMethodId: 'pm_test_123'
            })
        } as unknown as HttpRequest;

        const response = await processPayment(request, mockContext);

        expect(response.status).toBe(400);
        expect(response.jsonBody).toHaveProperty('error');
    });

    it('should return 500 when Stripe key is missing', async () => {
        delete process.env.STRIPE_SECRET_KEY;
        
        const request = {
            url: 'http://localhost:7071/api/processPayment',
            json: jest.fn().mockResolvedValue({
                amount: 1000,
                currency: 'USD',
                paymentMethodId: 'pm_test_123'
            })
        } as unknown as HttpRequest;

        const response = await processPayment(request, mockContext);

        expect(response.status).toBe(500);
        expect(response.jsonBody).toHaveProperty('error');
    });
});
