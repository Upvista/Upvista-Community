# Use the official Golang image as the base image
# Note: Using latest stable Go version (1.22) as 1.25.3 doesn't exist yet
# If you need 1.25.3 specifically, update go.mod to use an available version
FROM golang:1.22-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Use a minimal image for the final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Expose port 8080
EXPOSE 10000

# Run the application
CMD ["./main"]
