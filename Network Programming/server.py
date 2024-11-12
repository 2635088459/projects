# Import necessary libraries
import socket                   # For creating TCP sockets
from concurrent.futures import ThreadPoolExecutor  # For handling multiple clients simultaneously
from time import sleep         # For adding delays if needed

# Define server configuration
# 127.0.0.1 is localhost - meaning the server will only accept local connections
HOST = '127.0.0.1'
# Port 7000 is where the server will listen for connections
PORT = 7000

# This function handles individual client connections
# It runs in a separate thread for each client
def handle_client(socket, addr, port):
    # Keep connection alive until client disconnects
    while True:
        # Wait for and receive up to 1024 bytes of data from the client/proxy
        data = socket.recv(1024)
        
        # Check if received data is 'ping'
        if data == b"ping":    # b"ping" is the byte version of "ping"
            # Print received message along with client details
            print(f"Received {data.decode()!r} from {addr}:{port}")
            # Send 'pong' back to the client
            socket.sendall(b"pong")
            
        # If no data received (client disconnected)
        elif not data:
            # Close the connection
            socket.close()
            # Exit the loop
            break

# Create the main server socket
# 'with' statement ensures the socket is properly closed when we're done
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
    # Bind the socket to our specified HOST and PORT
    server_socket.bind((HOST, PORT))
    
    # Start listening for incoming connections
    server_socket.listen()
    print(f"Server listening on {HOST}:{PORT}")
    
    # Create a thread pool that can handle up to 5 clients at once
    with ThreadPoolExecutor(max_workers=5) as executor:
        # Keep the server running forever
        while True:
            # Wait for and accept new connection
            # accept() returns new socket and client's address
            client_socket, (client_addr, client_port) = server_socket.accept()
            print(f"Accepted connection from {client_addr}:{client_port}")
            
            # Submit this client to be handled by a new thread
            # This allows us to handle multiple clients simultaneously
            executor.submit(handle_client, client_socket, client_addr, client_port)