import socket  # Import socket to handle network communication.
import time  # Import time for managing time-related tasks.
import struct  # Import struct to help with packing and unpacking binary data.
import os  # Import os for file system interactions like checking file sizes.

class TCPTahoeSender:
    def __init__(self, host="localhost", port=5001):
        # Create a UDP socket for sending packets
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket to send data.
        self.server_addr = (host, port)  # Set up the server address we are sending data to.
        
        # Constants for packet handling
        self.PACKET_SIZE = 1024  # The total packet size, including headers and data.
        self.SEQ_ID_SIZE = 4  # The size of the sequence ID in each packet, which is 4 bytes.
        self.MESSAGE_SIZE = self.PACKET_SIZE - self.SEQ_ID_SIZE  # The actual data size we can send, minus the sequence ID size.
        self.TIMEOUT = 1.0  # The timeout value for retransmitting a packet, set to 1 second.
        
        # TCP Tahoe specific state variables
        self.cwnd = 1  # Initial congestion window size, starting with 1 packet.
        self.ssthresh = 64  # Initial threshold for transitioning from slow start to congestion avoidance.
        self.duplicate_acks = 0  # Counter for tracking duplicate acknowledgments.

        # State variables for tracking packets and timing
        self.sequence_number = 0  # Sequence number for each packet to keep them in order.
        self.packet_delays = []  # List to keep track of delays for packets.
        self.last_packet_time = None  # To track the time the last packet was sent, useful for jitter calculation.
        self.jitters = []  # List to keep track of jitter between packets.
        self.unacked_packets = {}  # Dictionary to store packets that are sent but not yet acknowledged.

    def create_packet(self, data):
        # Create a packet by adding the sequence number to the data
        seq_bytes = struct.pack('>i', self.sequence_number)  # Convert the sequence number into 4 bytes (big-endian format).
        return seq_bytes + data  # Combine the sequence number and data to form the packet.

    def handle_duplicate_ack(self):
        # Handle the event of receiving multiple duplicate acknowledgments
        self.ssthresh = max(self.cwnd // 2, 2)  # Cut the congestion window in half and set as threshold.
        self.cwnd = 1  # Reset congestion window to 1, similar to TCP Tahoe behavior (enter slow start).
        self.duplicate_acks = 0  # Reset duplicate ACK counter.

    def handle_timeout(self):
        # Handle a timeout situation (when ACK is not received within the timeout period)
        self.ssthresh = max(self.cwnd // 2, 2)  # Cut the congestion window in half.
        self.cwnd = 1  # Reset the congestion window to 1, entering slow start phase.

    def send_file(self, file_path):
        # Send a file using the TCP Tahoe algorithm for congestion control
        start_time = time.time()  # Record the start time for performance metrics.
        total_bytes = 0  # Track the total number of bytes sent successfully.
        file_size = os.path.getsize(file_path)  # Get the total size of the file to send.

        # Open the file in binary mode
        with open(file_path, 'rb') as f:
            while True:
                # Display the progress percentage
                progress = (self.sequence_number / file_size) * 100  # Calculate the percentage of file sent.
               # print(f"Progress: {min(int(progress), 100)}%", end='\r')  # Print progress without a newline to update dynamically.

                # Fill the window with new packets until the window size is reached
                while len(self.unacked_packets) < int(self.cwnd):
                    data = f.read(self.MESSAGE_SIZE)  # Read a chunk of data from the file.
                    if not data:
                        break  # Stop if no more data is left to read.

                    packet = self.create_packet(data)  # Create a packet from the sequence number and data.
                    self.sock.sendto(packet, self.server_addr)  # Send the packet to the server.
                    self.unacked_packets[self.sequence_number] = (packet, time.time(), data)  # Track the sent packet and time.
                    self.sequence_number += len(data)  # Increment the sequence number for the next packet.

                if not data and not self.unacked_packets:
                    # If all data is sent and acknowledged, stop the loop
                    break

                # Try to receive acknowledgments (ACKs) from the receiver
                try:
                    self.sock.settimeout(0.1)  # Set a timeout for waiting for ACKs.
                    ack_packet, _ = self.sock.recvfrom(self.PACKET_SIZE)  # Receive an ACK packet.
                    ack_seq = struct.unpack('>i', ack_packet[:self.SEQ_ID_SIZE])[0]  # Extract the sequence number from the ACK.

                    # If a new ACK is received, update the state
                    if ack_seq > min(self.unacked_packets.keys()):
                        current_time = time.time()  # Record the current time to calculate delay.
                        for seq in list(self.unacked_packets.keys()):
                            if seq < ack_seq:
                                _, send_time, data = self.unacked_packets[seq]  # Retrieve packet details.
                                delay = current_time - send_time  # Calculate how long it took for the packet to be acknowledged.
                                self.packet_delays.append(delay)  # Store the delay for this packet.

                                if self.last_packet_time is not None:
                                    jitter = abs(delay - self.last_packet_time)  # Calculate jitter as the difference between delays.
                                    self.jitters.append(jitter)  # Store the jitter value.

                                self.last_packet_time = delay  # Update the last packet time.
                                total_bytes += len(data)  # Update the total bytes sent.
                                del self.unacked_packets[seq]  # Remove the acknowledged packet from the unacked list.

                        # Adjust congestion window size based on the state
                        if self.cwnd < self.ssthresh:
                            self.cwnd += 1  # Slow start: exponentially increase window size.
                        else:
                            self.cwnd += 1 / self.cwnd  # Congestion avoidance: increase linearly.

                        self.duplicate_acks = 0  # Reset duplicate ACK counter.
                    else:
                        # If a duplicate ACK is received, increase the duplicate counter
                        self.duplicate_acks += 1
                        if self.duplicate_acks >= 3:
                            # If three duplicate ACKs are received, handle fast retransmission
                            self.handle_duplicate_ack()
                            first_seq = min(self.unacked_packets.keys())  # Find the first unacknowledged packet.
                            self.sock.sendto(self.unacked_packets[first_seq][0], self.server_addr)  # Retransmit it.

                except socket.timeout:
                    # If no ACK is received within the timeout, handle as a timeout event
                    self.handle_timeout()
                    if self.unacked_packets:
                        first_seq = min(self.unacked_packets.keys())  # Find the first unacknowledged packet.
                        self.sock.sendto(self.unacked_packets[first_seq][0], self.server_addr)  # Retransmit it.

      
        # Send an empty packet to signal that transmission is complete
        empty_packet = self.create_packet(b'')  # Create an empty packet to signal the end.
        self.sock.sendto(empty_packet, self.server_addr)  # Send the empty packet to the server.

        # Wait for final acknowledgment and FIN signal
        try:
            self.sock.settimeout(self.TIMEOUT)  # Set timeout for receiving the final ACK.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for an ACK.
            self.sock.recvfrom(self.PACKET_SIZE)  # Wait for a FIN (finish) message from the server.
            # Send a FINACK packet to acknowledge the server's FIN
            finack_packet = self.create_packet(b'==FINACK==')  # Create a packet containing FINACK.
            self.sock.sendto(finack_packet, self.server_addr)  # Send FINACK to the server.
        except socket.timeout:
            pass  # If no response is received, assume the end of communication.

        total_time = time.time() - start_time  # Calculate the total time taken for the file transfer.
        throughput = total_bytes / total_time if total_time > 0 else 0  # Calculate throughput in bytes per second.
        avg_delay = sum(self.packet_delays) / len(self.packet_delays) if self.packet_delays else 0  # Calculate average delay.
        avg_jitter = sum(self.jitters) / len(self.jitters) if self.jitters else 0  # Calculate average jitter.

        return throughput, avg_delay, avg_jitter  # Return the performance metrics.

    def close(self):
        # Close the socket connection to release resources
        self.sock.close()  # Close the socket.

def main():
    FILE_PATH = "./docker/file.mp3"  # Specify the path of the file to send.

    sender = TCPTahoeSender()  # Create an instance of the TCPTahoeSender class.
    try:
        throughput, delay, jitter = sender.send_file(FILE_PATH)  # Send the file and get the performance metrics.
        metric = 0.2 * (throughput / 2000) + 0.1 / jitter + 0.8 / delay if jitter > 0 and delay > 0 else 0  # Calculate a performance metric.
        
        # Print the metrics in a comma-separated format
        print(f"{throughput:.7f},{delay:.7f},{jitter:.7f},{metric:.7f}")
    finally:
        sender.close()  # Close the socket connection.

if __name__ == "__main__":
    main()  # Run the main function to start the program.
