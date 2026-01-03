FROM node:20-alpine
WORKDIR /app
RUN npm install -g spm-analyzer-mcp
CMD ["spm-analyzer-mcp"]