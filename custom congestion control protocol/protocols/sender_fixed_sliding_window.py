import socket  # Import socket module for network communication.
import time  # Import time module to track time-related functions.
import struct  # Import struct module to handle packing and unpacking of binary data.
import os  # Import os module to interact with the file system.

class FixedWindowSender:
    def __init__(self, host="localhost", port=5001):
        # Initialize a UDP socket for sending data to the server
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket.
        self.server_addr = (host, port)  # Define the server's address with hostname and port.
        
        # Constants used throughout the class
        self.PACKET_SIZE = 1024  # Set the total packet size in bytes.
        self.SEQ_ID_SIZE = 4  # Define the sequence ID size to be 4 bytes.
        self.MESSAGE_SIZE = self.PACKET_SIZE - self.SEQ_ID_SIZE  # Calculate the size for data excluding sequence ID.
        self.WINDOW_SIZE = 100  # Set the maximum number of packets that can be unacknowledged at any time.
        self.TIMEOUT = 1.0  # Set the timeout value for retransmission to 1 second.
        
        # State variables for tracking the progress
        self.sequence_number = 0  # Sequence number for each packet to ensure ordering.
        self.packet_delays = []  # List to track the delay for each packet.
        self.last_packet_time = None  # Timestamp for the last sent packet, used to calculate jitter.
        self.jitters = []  # List to track jitter values between packets.
        self.unacked_packets = {}  # Dictionary to keep track of packets that haven't been acknowledged.

    def create_packet(self, data):
        # Create a packet by combining the sequence number and data
        seq_bytes = struct.pack('>i', self.sequence_number)  # Convert the sequence number to bytes (big-endian format).
        return seq_bytes + data  # Return the combined sequence number and data as a single packet.
        
    def send_file(self, file_path):
        # Send the file using the fixed window protocol
        start_time = time.time()  # Record the start time to calculate throughput later.
        total_bytes = 0  # Track the total number of bytes successfully sent.
        file_size = os.path.getsize(file_path)  # Get the total size of the file.

        # Open the file for reading in binary mode
        with open(file_path, 'rb') as f:
            while True:
                # Show the progress of the file transfer in percentage
                progress = (self.sequence_number / file_size) * 100  # Calculate the progress percentage.
             #  print(f"Progress: {min(int(progress), 100)}%", end='\r')  # Print progress without a newline.

                # Fill the current window with new packets until the window is full
                while len(self.unacked_packets) < self.WINDOW_SIZE:
                    data = f.read(self.MESSAGE_SIZE)  # Read a block of data up to MESSAGE_SIZE bytes.
                    if not data:
                        break  # If no more data to read, exit the loop.

                    packet = self.create_packet(data)  # Create a packet containing the sequence number and data.
                    self.sock.sendto(packet, self.server_addr)  # Send the packet to the server.
                    self.unacked_packets[self.sequence_number] = (packet, time.time(), data)  # Track the sent packet and time.
                    self.sequence_number += len(data)  # Increment the sequence number by the length of the data.

                if not data and not self.unacked_packets:
                    # If no data is left to send and all packets have been acknowledged, break the loop.
                    break
                
                # Try to receive acknowledgments (ACKs) from the server
                try:
                    self.sock.settimeout(0.1)  # Set a short timeout for receiving ACKs.
                    ack_packet, _ = self.sock.recvfrom(self.PACKET_SIZE)  # Try to receive an ACK packet from the server.
                    ack_seq = struct.unpack('>i', ack_packet[:self.SEQ_ID_SIZE])[0]  # Extract the sequence number from the ACK packet.

                    # Process received ACKs and remove acknowledged packets from unacked_packets
                    if ack_seq > min(self.unacked_packets.keys()):
                        current_time = time.time()  # Record the current time to calculate delay.
                        for seq in list(self.unacked_packets.keys()):
                            if seq < ack_seq:
                                _, send_time, data = self.unacked_packets[seq]  # Get packet details.
                                delay = current_time - send_time  # Calculate the delay for this packet.
                                self.packet_delays.append(delay)  # Store the packet delay.
                                
                                if self.last_packet_time is not None:
                                    # Calculate jitter as the difference between this delay and the last packet delay.
                                    jitter = abs(delay - self.last_packet_time)
                                    self.jitters.append(jitter)  # Store the jitter value.

                                self.last_packet_time = delay  # Update the last packet time.
                                total_bytes += len(data)  # Update the total number of bytes successfully sent.
                                del self.unacked_packets[seq]  # Remove acknowledged packet from unacked_packets.

                except socket.timeout:
                    # If no ACK is received within the timeout period, retransmit all unacknowledged packets
                    current_time = time.time()  # Record the current time for retransmission purposes.
                    for seq, (packet, send_time, _) in self.unacked_packets.items():
                        if current_time - send_time > self.TIMEOUT:
                            # If the packet has exceeded the timeout, retransmit it.
                            self.sock.sendto(packet, self.server_addr)
                            self.unacked_packets[seq] = (packet, current_time, self.unacked_packets[seq][2])  # Update send time.

        # Send an empty packet to indicate the end of the transmission
        empty_packet = self.create_packet(b'')  # Create an empty packet.
        self.sock.sendto(empty_packet, self.server_addr)  # Send the empty packet to signal the end of the file.

        # Wait for final ACK and FIN signals from the server
        try:
            self.sock.settimeout(self.TIMEOUT)  # Set a timeout for receiving final ACKs.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for an ACK from the server.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for a FIN (finish) message from the server.
            # Send a FINACK packet to acknowledge the end of communication
            finack_packet = self.create_packet(b'==FINACK==')  # Create a packet with FINACK.
            self.sock.sendto(finack_packet, self.server_addr)  # Send the FINACK packet to the server.
        except socket.timeout:
            # If no response is received, assume the transmission is complete.
            pass
        
        total_time = time.time() - start_time  # Calculate the total time taken to send the file.
        throughput = total_bytes / total_time if total_time > 0 else 0  # Calculate throughput in bytes per second.
        avg_delay = sum(self.packet_delays) / len(self.packet_delays) if self.packet_delays else 0  # Calculate average delay per packet.
        avg_jitter = sum(self.jitters) / len(self.jitters) if self.jitters else 0  # Calculate average jitter.

        return throughput, avg_delay, avg_jitter  # Return performance metrics: throughput, average delay, and average jitter.

    def close(self):
        # Close the socket after completing the transmission
        self.sock.close()  # Close the socket to release resources.

def main():
    FILE_PATH = "./docker/file.mp3"  # Define the path to the file that will be sent.

    sender = FixedWindowSender()  # Create an instance of FixedWindowSender.
    try:
        throughput, delay, jitter = sender.send_file(FILE_PATH)  # Send the file and collect performance metrics.
        metric = 0.2 * (throughput / 2000) + 0.1 / jitter + 0.8 / delay if jitter > 0 and delay > 0 else 0  # Calculate a performance metric.
        # Print the metrics as well as the performance metric
        print(f"{throughput:.7f},{delay:.7f},{jitter:.7f},{metric:.7f}")  # Print throughput, delay, jitter, and metric in a comma-separated format.
    finally:
        sender.close()  # Close the socket regardless of success or failure.

if __name__ == "__main__":
    main()  # Entry point to execute the program.
