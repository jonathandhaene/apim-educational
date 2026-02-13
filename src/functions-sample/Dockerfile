# Use the official Azure Functions Node.js base image
FROM mcr.microsoft.com/azure-functions/node:4-node18

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy function code and configuration
COPY . .

# Build TypeScript
RUN npm install typescript && \
    npx tsc && \
    npm uninstall typescript

# Expose the default Azure Functions port
EXPOSE 80

# The base image already defines the ENTRYPOINT and CMD
# No need to specify them again
