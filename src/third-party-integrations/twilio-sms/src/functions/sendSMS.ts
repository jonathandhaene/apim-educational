import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import twilio from 'twilio';

interface SendSMSRequest {
    to: string;
    message: string;
}

export async function sendSMS(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`SMS function processed request for url "${request.url}"`);

    // Get Twilio credentials from environment variables
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const fromNumber = process.env.TWILIO_FROM_NUMBER;

    // Validate environment variables
    if (!accountSid || !authToken || !fromNumber) {
        context.log.error('Missing Twilio configuration');
        return {
            status: 500,
            jsonBody: {
                error: 'Twilio configuration is missing. Please set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_FROM_NUMBER environment variables.'
            }
        };
    }

    try {
        // Parse request body
        const body = await request.json() as SendSMSRequest;
        
        if (!body.to || !body.message) {
            return {
                status: 400,
                jsonBody: {
                    error: 'Missing required fields: to and message'
                }
            };
        }

        // Validate phone number format (basic validation)
        const phoneRegex = /^\+?[1-9]\d{1,14}$/;
        if (!phoneRegex.test(body.to)) {
            return {
                status: 400,
                jsonBody: {
                    error: 'Invalid phone number format. Please use E.164 format (e.g., +14155552671)'
                }
            };
        }

        // Initialize Twilio client
        const client = twilio(accountSid, authToken);

        // Send SMS
        const message = await client.messages.create({
            body: body.message,
            from: fromNumber,
            to: body.to
        });

        context.log(`SMS sent successfully. SID: ${message.sid}`);

        return {
            status: 200,
            jsonBody: {
                success: true,
                messageSid: message.sid,
                status: message.status,
                to: body.to,
                from: fromNumber,
                timestamp: new Date().toISOString()
            }
        };

    } catch (error: any) {
        context.log.error(`Error sending SMS: ${error.message}`);
        
        return {
            status: 500,
            jsonBody: {
                success: false,
                error: 'Failed to send SMS',
                details: error.message
            }
        };
    }
}

app.http('sendSMS', {
    methods: ['POST'],
    authLevel: 'function',
    handler: sendSMS
});
