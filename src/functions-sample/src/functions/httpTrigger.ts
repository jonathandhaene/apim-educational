import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';

export async function httpTrigger(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`HTTP function processed request for url "${request.url}"`);

    const name = request.query.get('name') || await request.text() || 'World';

    return {
        status: 200,
        jsonBody: {
            message: `Hello, ${name}!`,
            timestamp: new Date().toISOString(),
            functionName: 'sample-api-function',
            version: '1.0.0'
        },
        headers: {
            'Content-Type': 'application/json'
        }
    };
}

app.http('httpTrigger', {
    methods: ['GET', 'POST'],
    authLevel: 'function',
    handler: httpTrigger
});
