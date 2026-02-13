import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import Stripe from 'stripe';

interface ProcessPaymentRequest {
    amount: number;
    currency: string;
    paymentMethodId: string;
    description?: string;
    metadata?: Record<string, string>;
}

export async function processPayment(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`Payment function processed request for url "${request.url}"`);

    // Get Stripe API key from environment variables
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;

    // Validate environment variables
    if (!stripeSecretKey) {
        context.log.error('Missing Stripe configuration');
        return {
            status: 500,
            jsonBody: {
                error: 'Stripe configuration is missing. Please set STRIPE_SECRET_KEY environment variable.'
            }
        };
    }

    try {
        // Parse request body
        const body = await request.json() as ProcessPaymentRequest;
        
        // Validate required fields
        if (!body.amount || !body.currency || !body.paymentMethodId) {
            return {
                status: 400,
                jsonBody: {
                    error: 'Missing required fields: amount, currency, and paymentMethodId'
                }
            };
        }

        // Validate amount (must be positive and in cents)
        if (body.amount <= 0 || !Number.isInteger(body.amount)) {
            return {
                status: 400,
                jsonBody: {
                    error: 'Invalid amount. Must be a positive integer in cents (e.g., 1000 for $10.00)'
                }
            };
        }

        // Validate currency (3-letter ISO code)
        const currencyRegex = /^[A-Z]{3}$/;
        if (!currencyRegex.test(body.currency.toUpperCase())) {
            return {
                status: 400,
                jsonBody: {
                    error: 'Invalid currency code. Use 3-letter ISO code (e.g., USD, EUR, GBP)'
                }
            };
        }

        // Initialize Stripe client
        const stripe = new Stripe(stripeSecretKey, {
            apiVersion: '2023-10-16',
        });

        // Create payment intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: body.amount,
            currency: body.currency.toLowerCase(),
            payment_method: body.paymentMethodId,
            confirm: true,
            description: body.description || 'Payment via Azure Function',
            metadata: body.metadata || {},
            automatic_payment_methods: {
                enabled: true,
                allow_redirects: 'never'
            }
        });

        context.log(`Payment processed successfully. Intent ID: ${paymentIntent.id}`);

        return {
            status: 200,
            jsonBody: {
                success: true,
                paymentIntentId: paymentIntent.id,
                status: paymentIntent.status,
                amount: paymentIntent.amount,
                currency: paymentIntent.currency,
                created: paymentIntent.created,
                timestamp: new Date().toISOString()
            }
        };

    } catch (error: any) {
        context.log.error(`Error processing payment: ${error.message}`);
        
        // Handle Stripe-specific errors
        if (error.type === 'StripeCardError') {
            return {
                status: 402,
                jsonBody: {
                    success: false,
                    error: 'Card was declined',
                    code: error.code,
                    decline_code: error.decline_code
                }
            };
        }

        if (error.type === 'StripeInvalidRequestError') {
            return {
                status: 400,
                jsonBody: {
                    success: false,
                    error: 'Invalid request to Stripe',
                    message: error.message
                }
            };
        }

        return {
            status: 500,
            jsonBody: {
                success: false,
                error: 'Failed to process payment',
                details: error.message
            }
        };
    }
}

app.http('processPayment', {
    methods: ['POST'],
    authLevel: 'function',
    handler: processPayment
});
