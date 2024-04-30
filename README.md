# HTTP Client in Assembly

This project is a simple HTTP client implemented in Assembly language. It is capable of making HTTP requests to a specified server and receiving responses. The client supports the most common HTTP methods: GET, POST, PUT, DELETE, and OPTIONS.

## Features

- HTTP/1.0 protocol support
- Supports GET, POST, PUT, DELETE, and OPTIONS methods
- Parses URL and extracts hostname and URI
- Resolves hostname to IP address
- Connects to the server via a socket
- Sends HTTP request and receives response
- Error handling for socket creation, connection, and data transmission

## How to Run Locally

This project uses Docker for easy setup and execution. You need to have Docker and Docker Compose installed on your machine to run this project.

### Steps:

1. Clone the repository to your local machine.
2. Navigate to the project directory.
3. Build the Docker image and run the container using Docker Compose with the following command:

```bash
docker-compose up --build
```

This command will build a Docker image based on the provided Dockerfile, which installs the necessary dependencies, compiles the Assembly code, and runs the HTTP client. The client will make a request to `http://www.google.com` by default, as specified in the Dockerfile.

Please note that this HTTP client is a low-level implementation for educational purposes and is not intended for production use. It does not support HTTPS, and error handling is minimal. For production use, consider using a high-level HTTP client library or tool.

## Known Issues

* The response body is not being read completely. The client reads only the first part of the response body and stops reading after a certain point for some reason.