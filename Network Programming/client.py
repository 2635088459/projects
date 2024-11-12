# Import required libraries
import socket                # For network communications
from time import sleep      # For adding delay between pings
import json                 # For creating JSON messages

# Proxy server connection details
PROXY_HOST = '127.0.0.1'    # Connect to proxy on localhost
PROXY_PORT = 6000           # Proxy's port number

# Create a new TCP socket
# 'with' ensures the socket is properly closed when we're done
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    # Connect to the proxy server
    s.connect((PROXY_HOST, PROXY_PORT))
    print(f"Connected to proxy server at {PROXY_HOST}:{PROXY_PORT}")

    # Keep sending messages forever
    while True:
        # Create the JSON message that proxy expects
        message = {
            "server_ip": "127.0.0.1",    # Final server's IP
            "server_port": 7000,         # Final server's port
            "message": "ping"            # The message to send
        }

        # Convert message to JSON string and then to bytes
        # and send it to proxy
        s.sendall(json.dumps(message).encode())

        # Wait for and receive proxy's response
        data = s.recv(1024)

        # Print what we received
        print(f"Received {data.decode()!r} through proxy")
        
        # Wait 1 second before sending next ping
        sleep(1)