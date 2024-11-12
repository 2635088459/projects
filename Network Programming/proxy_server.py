# Import required libraries
import socket                   # For network communications
from concurrent.futures import ThreadPoolExecutor  # For handling multiple clients
import json                     # For parsing JSON messages

# Proxy server configuration
HOST = '127.0.0.1'             # Listen on localhost
PORT = 6000                    # Proxy's port number

# List of IP addresses that aren't allowed to receive forwarded messages
BLOCKLIST = [
    "192.168.1.1",
    "10.0.0.1",
    # Add more blocked IPs here
    # "127.0.0.1",
]

# Function to forward messages to the actual server
def forward_to_server(server_ip, server_port, message):
    """Forward message to server and get response"""
    try:
        # Create a new socket for server communication
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
            # Connect to the actual server
            server_socket.connect((server_ip, server_port))
            # Forward the message
            server_socket.sendall(message.encode())
            # Wait for and return the server's response
            return server_socket.recv(1024)
    except Exception as e:
        # If anything goes wrong, return error message
        return f"Error connecting to server: {str(e)}".encode()

# Function to handle each client connection
def handle_client(client_socket, addr, port):
    """Handle client connection"""
    # Keep connection alive until client disconnects
    while True:
        try:
            # Receive data from client
            data = client_socket.recv(1024)
            if not data:
                break

            try:
                # Convert received JSON string to Python dictionary
                request = json.loads(data.decode())
                
                # Extract information from the request
                server_ip = request.get('server_ip')      # Where to forward the message
                server_port = request.get('server_port')  # Which port to use
                message = request.get('message')          # The actual message

                # Check if the target server is blocked
                if server_ip in BLOCKLIST:
                    client_socket.sendall(b"Error: Server IP is blocked")
                    continue

                # Forward the message to actual server and get response
                response = forward_to_server(server_ip, server_port, message)
                print(f"Forwarding message from {addr}:{port} to {server_ip}:{server_port}")
                
                # Send server's response back to client
                client_socket.sendall(response)

            except json.JSONDecodeError:
                # If the message isn't valid JSON
                client_socket.sendall(b"Error: Invalid JSON format")
            except Exception as e:
                # If any other error occurs
                client_socket.sendall(f"Error: {str(e)}".encode())

        except Exception as e:
            print(f"Error handling client: {e}")
            break

    # Close the client connection when done
    client_socket.close()

# Create the main proxy socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as proxy_socket:
    # Bind it to our HOST and PORT
    proxy_socket.bind((HOST, PORT))
    
    # Start listening for connections
    proxy_socket.listen()
    print(f"Proxy server listening on {HOST}:{PORT}")

    # Create thread pool for handling multiple clients
    with ThreadPoolExecutor(max_workers=5) as executor:
        # Keep proxy running forever
        while True:
            # Accept new client connection
            client_socket, (client_addr, client_port) = proxy_socket.accept()
            print(f"Accepted connection from {client_addr}:{client_port}")
            
            # Handle this client in a new thread
            executor.submit(handle_client, client_socket, client_addr, client_port)