# Upvista Community Backend

A Golang backend service for the Upvista Community platform built with the Gin web framework.

## Features

- RESTful API endpoints
- Health check endpoint
- Versioned API routes
- Clean project structure

## Getting Started

### Prerequisites

- Go 1.19 or higher
- Git

### Installation

1. Clone the repository
2. Navigate to the backend directory:
   ```bash
   cd backend
   ```

3. Install dependencies:
   ```bash
   go mod tidy
   ```

4. Run the server:
   ```bash
   go run main.go
   ```

The server will start on `http://localhost:8080`

## API Endpoints

### Health Check
- `GET /health` - Returns server health status

### Welcome
- `GET /` - Returns welcome message

### API v1
- `GET /api/v1/status` - Returns API status

## Project Structure

```
backend/
├── main.go          # Main application file
├── go.mod           # Go module file
├── go.sum           # Go module checksums
└── README.md        # This file
```

## Development

To run in development mode:
```bash
go run main.go
```

To build the application:
```bash
go build -o upvista-backend main.go
```

## Deployment

### Deploy to Render

This application is configured for deployment on Render.com:

1. **Push your code to GitHub** (make sure the backend folder is in your repository)

2. **Connect to Render**:
   - Go to [render.com](https://render.com)
   - Sign up/Login with your GitHub account
   - Click "New +" and select "Web Service"

3. **Configure the service**:
   - Connect your GitHub repository
   - Set the following:
     - **Name**: `upvista-community-backend`
     - **Root Directory**: `backend`
     - **Environment**: `Docker`
     - **Dockerfile Path**: `./Dockerfile`
     - **Plan**: `Free` (or upgrade as needed)

4. **Environment Variables** (optional):
   - `GIN_MODE`: `release` (for production mode)
   - `PORT`: `10000` (Render's default port)

5. **Deploy**:
   - Click "Create Web Service"
   - Render will automatically build and deploy your application
   - Your API will be available at `https://your-app-name.onrender.com`

### Manual Docker Deployment

You can also deploy using Docker:

```bash
# Build the Docker image
docker build -t upvista-backend .

# Run the container
docker run -p 8080:8080 upvista-backend
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request
