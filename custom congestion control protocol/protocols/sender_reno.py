import socket  # Import the socket library for network communication.
import time  # Import time to track transmission delays and manage timeouts.
import struct  # Import struct for handling binary data.
import os  # Import os to interact with the file system.

class TCPRenoSender:
    def __init__(self, host="localhost", port=5001):
        # Create a UDP socket to send packets to the server
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket for sending data.
        self.server_addr = (host, port)  # Define the server address where packets will be sent.
        
        # Constants for packet configuration
        self.PACKET_SIZE = 1024  # Define the total size of each packet in bytes.
        self.SEQ_ID_SIZE = 4  # The size of the sequence ID is set to 4 bytes.
        self.MESSAGE_SIZE = self.PACKET_SIZE - self.SEQ_ID_SIZE  # Calculate the size available for actual data.
        self.TIMEOUT = 1.0  # Set the timeout value for waiting for an ACK, in seconds.
        
        # TCP Reno specific settings
        self.cwnd = 1  # Start with a congestion window (cwnd) size of 1 packet.
        self.ssthresh = 64  # Set the initial slow start threshold to 64 packets.
        self.duplicate_acks = 0  # Track the number of duplicate ACKs received.
        self.in_fast_recovery = False  # Boolean to keep track if we are in the fast recovery phase.
        
        # Variables for tracking packet and timing details
        self.sequence_number = 0  # Sequence number for identifying packets.
        self.packet_delays = []  # List to store delays for each packet.
        self.last_packet_time = None  # To store the time at which the last packet was sent.
        self.jitters = []  # List to store the jitter values between packets.
        self.unacked_packets = {}  # Dictionary to track sent but unacknowledged packets.
        
    def create_packet(self, data):
        # Create a packet by combining sequence number and data
        seq_bytes = struct.pack('>i', self.sequence_number)  # Convert sequence number to bytes (big-endian).
        return seq_bytes + data  # Concatenate sequence number bytes with the data to form a complete packet.
        
    def handle_duplicate_ack(self):
        # Handle duplicate ACKs for fast retransmission (Reno behavior)
        if not self.in_fast_recovery:
            # If not already in fast recovery, enter fast recovery
            self.ssthresh = max(self.cwnd // 2, 2)  # Cut the congestion window in half and set it as the threshold.
            self.cwnd = self.ssthresh + 3  # Increase the congestion window by 3 packets to continue sending.
            self.in_fast_recovery = True  # Mark that we are in fast recovery.
        else:
            # If already in fast recovery, increment the congestion window by 1 for each additional duplicate ACK
            self.cwnd += 1
        
    def handle_timeout(self):
        # Handle timeout by entering slow start again
        self.in_fast_recovery = False  # Exit fast recovery if currently in it.
        self.ssthresh = max(self.cwnd // 2, 2)  # Reduce congestion window size by half and set as the threshold.
        self.cwnd = 1  # Reset congestion window to 1 to start slow start again.
        self.duplicate_acks = 0  # Reset the duplicate ACK counter.
        
    def send_file(self, file_path):
        # Send the file using the TCP Reno congestion control mechanism
        start_time = time.time()  # Record the time when file transfer starts.
        total_bytes = 0  # Track the total number of bytes successfully sent.
        file_size = os.path.getsize(file_path)  # Get the total size of the file to be sent.
        
        # Open the file in binary mode for reading
        with open(file_path, 'rb') as f:
            while True:
                # Display the progress of the file transfer
                progress = (self.sequence_number / file_size) * 100  # Calculate the percentage of the file sent.
               # print(f"Progress: {min(int(progress), 100)}%", end='\r')  # Print the progress percentage.
                
                # Fill the congestion window with new packets to send
                while len(self.unacked_packets) < int(self.cwnd):
                    data = f.read(self.MESSAGE_SIZE)  # Read a chunk of data equal to MESSAGE_SIZE.
                    if not data:
                        break  # Stop reading if no data is left in the file.
                    
                    packet = self.create_packet(data)  # Create a packet with sequence number and data.
                    self.sock.sendto(packet, self.server_addr)  # Send the packet to the server.
                    self.unacked_packets[self.sequence_number] = (packet, time.time(), data)  # Store packet information.
                    self.sequence_number += len(data)  # Increment the sequence number by the data length.
                
                if not data and not self.unacked_packets:
                    # If no more data to send and all packets are acknowledged, end the loop
                    break
                
                # Try to receive ACKs from the server
                try:
                    self.sock.settimeout(0.1)  # Set the timeout for waiting for ACKs.
                    ack_packet, _ = self.sock.recvfrom(self.PACKET_SIZE)  # Receive an ACK packet from the server.
                    ack_seq = struct.unpack('>i', ack_packet[:self.SEQ_ID_SIZE])[0]  # Extract the sequence number from the ACK.

                    if ack_seq > min(self.unacked_packets.keys()):
                        # If the ACK sequence is greater than the smallest unacknowledged sequence
                        current_time = time.time()  # Record the current time to calculate delay.
                        for seq in list(self.unacked_packets.keys()):
                            if seq < ack_seq:
                                _, send_time, data = self.unacked_packets[seq]  # Get details of the acknowledged packet.
                                delay = current_time - send_time  # Calculate the delay of the packet.
                                self.packet_delays.append(delay)  # Store the packet delay.

                                if self.last_packet_time is not None:
                                    # Calculate jitter as the difference between delays of successive packets
                                    jitter = abs(delay - self.last_packet_time)
                                    self.jitters.append(jitter)  # Store the jitter value.

                                self.last_packet_time = delay  # Update the last packet time.
                                total_bytes += len(data)  # Update the total bytes sent successfully.
                                del self.unacked_packets[seq]  # Remove the acknowledged packet from the list.

                        # Exit fast recovery if we're currently in it
                        if self.in_fast_recovery:
                            self.cwnd = self.ssthresh  # Set the congestion window to the threshold value.
                            self.in_fast_recovery = False  # Mark that we have exited fast recovery.
                        
                        # Normal window adjustment
                        if self.cwnd < self.ssthresh:
                            # Slow start: increase window size exponentially
                            self.cwnd += 1
                        else:
                            # Congestion avoidance: increase window size linearly
                            self.cwnd += 1 / self.cwnd
                        
                        self.duplicate_acks = 0  # Reset the duplicate ACK counter.
                    else:
                        # If the ACK is a duplicate
                        self.duplicate_acks += 1
                        if self.duplicate_acks >= 3:
                            # If three duplicate ACKs are received, handle it as a packet loss
                            self.handle_duplicate_ack()
                            # Retransmit the first unacknowledged packet
                            if self.unacked_packets:
                                first_seq = min(self.unacked_packets.keys())
                                self.sock.sendto(self.unacked_packets[first_seq][0], self.server_addr)
                
                except socket.timeout:
                    # Handle timeout by retransmitting the first unacknowledged packet
                    self.handle_timeout()  # Handle the timeout event.
                    if self.unacked_packets:
                        first_seq = min(self.unacked_packets.keys())  # Find the first unacknowledged packet.
                        self.sock.sendto(self.unacked_packets[first_seq][0], self.server_addr)  # Retransmit it.
        
        # Send an empty packet to signal the end of transmission
        empty_packet = self.create_packet(b'')  # Create an empty packet with just the sequence number.
        self.sock.sendto(empty_packet, self.server_addr)  # Send the empty packet to the server.
        
        # Wait for the final acknowledgment and FIN signal from the server
        try:
            self.sock.settimeout(self.TIMEOUT)  # Set the timeout for waiting for ACK.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for an ACK from the server.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for a FIN message from the server.
            # Send a FINACK to acknowledge the server's FIN
            finack_packet = self.create_packet(b'==FINACK==')  # Create a FINACK packet to send back.
            self.sock.sendto(finack_packet, self.server_addr)  # Send the FINACK packet.
        except socket.timeout:
            pass  # If no response, assume transmission is complete.
        
        total_time = time.time() - start_time  # Calculate the total time taken to send the file.
        throughput = total_bytes / total_time if total_time > 0 else 0  # Calculate the throughput.
        avg_delay = sum(self.packet_delays) / len(self.packet_delays) if self.packet_delays else 0  # Calculate average delay.
        avg_jitter = sum(self.jitters) / len(self.jitters) if self.jitters else 0  # Calculate average jitter.
        
        return throughput, avg_delay, avg_jitter  # Return throughput, average delay, and jitter as performance metrics.
        
    def close(self):
        # Close the socket to release resources
        self.sock.close()  # Close the UDP socket.

def main():
    FILE_PATH = "./docker/file.mp3"  # Define the path to the file that will be sent.
    
    sender = TCPRenoSender()  # Create an instance of the TCPRenoSender class.
    try:
        throughput, delay, jitter = sender.send_file(FILE_PATH)  # Send the file and get the performance metrics.
        metric = 0.2 * (throughput / 2000) + 0.1 / jitter + 0.8 / delay if jitter > 0 and delay > 0 else 0  # Calculate a performance metric.
        # Print the performance metrics in a comma-separated format.
        print(f"{throughput:.7f},{delay:.7f},{jitter:.7f},{metric:.7f}")
    finally:
        sender.close()  # Close the sender socket.
        
if __name__ == "__main__":
    main()  # Call the main function to start the program.
