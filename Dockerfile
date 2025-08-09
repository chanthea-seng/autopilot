# 1. Use Node.js base image
FROM node:18-alpine AS builder

# 2. Set working directory
WORKDIR /app

# 3. Copy package files and install dependencies
COPY package*.json ./
RUN npm install --legacy-peer-deps

# 4. Copy all files and build Next.js
COPY . .
RUN npm run build

# 5. Production image
FROM node:18-alpine AS runner
WORKDIR /app

# Copy only the built output and node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules

# Set Next.js to production
ENV NODE_ENV=production
EXPOSE 3000

# Run Next.js
CMD ["npm", "start"]
