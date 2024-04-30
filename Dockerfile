FROM ubuntu:latest

# Install dependencies

RUN apt-get update && apt-get install -y nasm gcc-multilib make

# Copy the source code to the container

COPY . /app

# Set the working directory

WORKDIR /app

# Compile the source code

RUN make

# Run the executable

CMD ["/app/http_client", "http://www.google.com"]