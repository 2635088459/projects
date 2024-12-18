import socket  # Import socket for network communication.
import time  # Import time for tracking transmission delays and timeouts.
import struct  # Import struct for handling binary data formatting.
import os  # Import os for file handling functions.

class StopAndWaitSender:
    def __init__(self, host="localhost", port=5001):
        # Initialize the UDP socket and set up the server address
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket for communication.
        self.server_addr = (host, port)  # Define the address of the server (host and port).
        
        # Constants
        self.PACKET_SIZE = 1024  # Define the packet size to be 1024 bytes.
        self.SEQ_ID_SIZE = 4  # Define the size of the sequence ID to be 4 bytes.
        self.MESSAGE_SIZE = self.PACKET_SIZE - self.SEQ_ID_SIZE  # Define the size of the message part of each packet.

        # State variables
        self.sequence_number = 0  # Sequence number to keep track of packet ordering.
        self.packet_delays = []  # List to store the delay of each packet for performance metrics.
        self.last_packet_time = None  # Timestamp of the last packet sent, used for jitter calculation.
        self.jitters = []  # List to store jitter values for each packet.
        self.timeout = 1.0  # Timeout value for retransmission, set to 1 second.

    def create_packet(self, data):
        # Create a packet by attaching the sequence number to the data
        seq_bytes = struct.pack('>i', self.sequence_number)  # Pack the sequence number into 4 bytes (big-endian format).
        return seq_bytes + data  # Concatenate sequence number bytes with the actual data.

    def send_file(self, file_path):
        # Send a file to the receiver using Stop-and-Wait protocol
        start_time = time.time()  # Record the start time for throughput calculation.
        total_bytes = 0  # Track the total number of bytes successfully sent.

        with open(file_path, 'rb') as f:
            while True:
                data = f.read(self.MESSAGE_SIZE)  # Read a chunk of data equal to MESSAGE_SIZE.
                if not data:
                    break  # If no data is left to read, exit the loop.

                packet = self.create_packet(data)  # Create a packet with the sequence number and data.
                packet_sent = False  # Track whether the packet has been successfully acknowledged.

                while not packet_sent:
                    send_time = time.time()  # Record the send time for calculating delay.
                    self.sock.sendto(packet, self.server_addr)  # Send the packet to the server.

                    try:
                        self.sock.settimeout(self.timeout)  # Set a timeout for waiting for ACK.
                        ack_packet, _ = self.sock.recvfrom(self.PACKET_SIZE)  # Wait to receive an ACK.
                        ack_seq = struct.unpack('>i', ack_packet[:self.SEQ_ID_SIZE])[0]  # Extract the sequence number from the ACK.

                        if ack_seq > self.sequence_number:
                            # If the ACK sequence number is greater than the current sequence number,
                            # the packet has been successfully received.
                            delay = time.time() - send_time  # Calculate the round-trip time for the packet.
                            self.packet_delays.append(delay)  # Append the delay to the packet delays list.

                            if self.last_packet_time is not None:
                                # Calculate jitter as the absolute difference between current delay and last packet time.
                                jitter = abs(delay - self.last_packet_time)
                                self.jitters.append(jitter)  # Append jitter value to the jitters list.

                            self.last_packet_time = delay  # Update the last packet time to the current delay.
                            packet_sent = True  # Mark the packet as sent.
                            total_bytes += len(data)  # Update total bytes sent.
                            self.sequence_number += len(data)  # Increment the sequence number by the length of the data.

                    except socket.timeout:
                        # If timeout occurs, retransmit the packet
                        continue  # Retransmit the packet.

        self.send_fin_sequence()  # Send a sequence to finalize the transmission.

        total_time = time.time() - start_time  # Calculate the total time taken for transmission.
        throughput = total_bytes / total_time if total_time > 0 else 0  # Calculate throughput.
        avg_delay = sum(self.packet_delays) / len(self.packet_delays) if self.packet_delays else 0  # Calculate average packet delay.
        avg_jitter = sum(self.jitters) / len(self.jitters) if self.jitters else 0  # Calculate average jitter.

        return throughput, avg_delay, avg_jitter  # Return the performance metrics.

    def send_fin_sequence(self):
        # Send an empty packet to signal the end of transmission
        empty_packet = self.create_packet(b'')  # Create an empty packet with just the sequence number.
        self.sock.sendto(empty_packet, self.server_addr)  # Send the empty packet to indicate end of data.

        try:
            self.sock.settimeout(self.timeout)  # Set a timeout for receiving the final ACK.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for the final ACK from the receiver.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for a FIN message from the receiver.
            finack_packet = self.create_packet(b'==FINACK==')  # Create a FINACK packet to acknowledge the FIN.
            self.sock.sendto(finack_packet, self.server_addr)  # Send the FINACK packet.
        except socket.timeout:
            # If no response is received within the timeout, assume the transmission is complete.
            pass

    def close(self):
        # Close the socket to release resources
        self.sock.close()  # Close the socket after the transmission is complete.

def main():
    FILE_PATH = "./docker/file.mp3"  # Define the file path for the file to be sent.

    sender = StopAndWaitSender()  # Create an instance of the StopAndWaitSender class.
    try:
        throughput, delay, jitter = sender.send_file(FILE_PATH)  # Send the file and get the performance metrics.
        metric = 0.2 * (throughput / 2000) + 0.1 / jitter + 0.8 / delay if jitter > 0 and delay > 0 else 0  # Calculate performance metric.
        # Print required comma-separated output
        print(f"{throughput:.7f},{delay:.7f},{jitter:.7f}, {metric:.7f}")  # Print metrics in comma-separated format for easy reading.
    finally:
        sender.close()  # Close the socket to clean up resources.

if __name__ == "__main__":
    main()  # Call the main function to start the program.
