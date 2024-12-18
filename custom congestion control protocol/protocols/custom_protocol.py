import socket  # Import the socket module for network communication.
import time  # Import time module for managing delays and timeouts.
import struct  # Import struct module for handling binary data.
import os  # Import os module to interact with the file system.
from collections import deque  # Import deque to use a double-ended queue for storing values.

class OptimizedAdaptiveSender:
    def __init__(self, host="localhost", port=5001):
        # Create a UDP socket for sending data to the server
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)  # Create a UDP socket for communication.
        self.server_addr = (host, port)  # Define the server's address with hostname and port.
        
        # Constants - Optimized to improve performance
        self.PACKET_SIZE = 1024  # Total packet size, including headers and data.
        self.SEQ_ID_SIZE = 4  # Size of the sequence ID, which is 4 bytes.
        self.MESSAGE_SIZE = self.PACKET_SIZE - self.SEQ_ID_SIZE  # Size available for actual data after sequence ID.
        self.INIT_WINDOW = 32  # Initial congestion window size to send multiple packets at once.
        self.MAX_WINDOW = 256  # Maximum congestion window to control the amount of data sent.
        
        # State variables for tracking data
        self.sequence_number = 0  # Sequence number to ensure packets are sent in order.
        self.packet_delays = []  # List to store the delays of each packet.
        self.jitters = []  # List to store the jitter values.
        self.last_delay = None  # To track the last delay, used to calculate jitter.
        self.unacked_packets = {}  # Dictionary to track packets that have been sent but not acknowledged.
        
        # Enhanced RTT (Round Trip Time) tracking
        self.rtt_samples = deque(maxlen=20)  # Store a limited number of recent RTT samples.
        self.rttvar = 0  # RTT variation, used for timeout calculations.
        self.srtt = 0  # Smoothed RTT value.
        self.min_rtt = float('inf')  # Store the minimum RTT observed.

        # Bandwidth estimation using Exponential Moving Average (EMA)
        self.ema_bandwidth = 100000  # Estimated initial bandwidth (in bits per second).
        self.ema_alpha = 0.125  # EMA factor for calculating bandwidth, controls how much new samples impact the estimate.
        
        # Congestion control variables
        self.cwnd = self.INIT_WINDOW  # Current congestion window size.
        self.ssthresh = 128  # Slow start threshold, controls the transition between phases.
        self.loss_count = 0  # Track packet losses to adjust the window.
        self.mode = "AGGRESSIVE"  # Different modes of operation: AGGRESSIVE, NORMAL, RECOVERY.
        self.last_window_update = time.time()  # Time of the last congestion window update.
        self.consecutive_success = 0  # Counter for consecutive successful transmissions.
        
        # Adaptive timing variables
        self.last_send_time = 0  # Track the last time a packet was sent to handle pacing.
        self.pacing_interval = 0.00005  # Pacing interval to control the rate of sending packets.

    def create_packet(self, data):
        # Create a packet by adding a sequence number to the data
        seq_bytes = struct.pack('>i', self.sequence_number)  # Convert the sequence number to bytes (big-endian format).
        return seq_bytes + data  # Concatenate sequence number bytes with data to form a complete packet.

    def update_rtt(self, rtt):
        """Calculate and update RTT using weighted moving average"""
        if not self.srtt:
            # If no smoothed RTT exists, set it to the current RTT
            self.srtt = rtt
            self.rttvar = rtt / 2  # Initial RTT variation is half of RTT.
        else:
            # Update RTT variance and smoothed RTT using exponential moving average
            self.rttvar = 0.75 * self.rttvar + 0.25 * abs(self.srtt - rtt)
            self.srtt = 0.875 * self.srtt + 0.125 * rtt

        # Update the minimum RTT if the new RTT is lower
        self.min_rtt = min(self.min_rtt, rtt)
        # Add the RTT sample to the deque
        self.rtt_samples.append(rtt)

    def estimate_bandwidth(self, bytes_acked, time_taken):
        """Estimate the bandwidth using exponential moving average"""
        if time_taken > 0:
            # Calculate the current bandwidth sample
            bw_sample = bytes_acked / time_taken
            # Update the bandwidth estimate using EMA
            self.ema_bandwidth = self.ema_alpha * bw_sample + (1 - self.ema_alpha) * self.ema_bandwidth

    def get_timeout(self):
        """Calculate the timeout value using the Jacobson/Karels algorithm"""
        # Timeout is calculated based on smoothed RTT and its variation
        return self.srtt + 4 * self.rttvar

    def adjust_window(self, success, bytes_acked=0, rtt=None):
        # Adjust the congestion window size based on success or packet loss
        current_time = time.time()
        
        if success:
            self.consecutive_success += 1  # Increment successful transmission count
            
            if self.mode == "AGGRESSIVE":
                if self.consecutive_success > 10:
                    # Increase the window more aggressively if network conditions are good
                    self.cwnd = min(self.cwnd * 2, self.MAX_WINDOW)
                else:
                    # Increase window size less aggressively
                    self.cwnd = min(self.cwnd + 2, self.MAX_WINDOW)

                if rtt and rtt > 1.1 * self.min_rtt:
                    # If RTT is higher than a threshold, switch to normal mode
                    self.mode = "NORMAL"

            elif self.mode == "NORMAL":
                # Linear increase in congestion window during congestion avoidance
                if current_time - self.last_window_update >= self.srtt:
                    if self.cwnd < self.ssthresh:
                        self.cwnd += 1  # Increase linearly in slow start
                    else:
                        self.cwnd += 1 / self.cwnd  # Increase slowly in congestion avoidance
                    self.last_window_update = current_time

            elif self.mode == "RECOVERY":
                if self.consecutive_success >= 5:
                    # Switch back to normal mode after recovering successfully
                    self.mode = "NORMAL"
                    self.cwnd = self.ssthresh

        else:
            # Handle packet loss
            self.consecutive_success = 0
            self.loss_count += 1
            
            if self.loss_count >= 3:
                # Enter recovery mode if three losses are detected
                self.mode = "RECOVERY"
                self.ssthresh = max(self.cwnd // 2, self.INIT_WINDOW)  # Reduce ssthresh
                self.cwnd = self.INIT_WINDOW  # Reset congestion window
                self.loss_count = 0
            else:
                # Reduce the congestion window gradually
                self.cwnd = max(self.cwnd * 0.7, self.INIT_WINDOW)

    def send_file(self, file_path):
        # Send the file using the adaptive congestion control
        start_time = time.time()  # Record the start time of the transmission
        total_bytes = 0  # Track total bytes successfully sent
        file_size = os.path.getsize(file_path)  # Get the total size of the file to send
        last_progress = -1  # Track the last progress percentage shown

        with open(file_path, 'rb') as f:
            while True:
                # Display progress
                progress = int((self.sequence_number / file_size) * 100)
                if progress != last_progress:
                  #  print(f"Progress: {min(progress, 100)}%", end='\r')  # Print progress dynamically
                    last_progress = progress
                
                # Send packets until the congestion window limit is reached
                while len(self.unacked_packets) < int(self.cwnd):
                    data = f.read(self.MESSAGE_SIZE)  # Read data up to MESSAGE_SIZE
                    if not data:
                        break  # Stop if there's no more data

                    packet = self.create_packet(data)  # Create packet with sequence number and data
                    self.sock.sendto(packet, self.server_addr)  # Send the packet to the server
                    self.unacked_packets[self.sequence_number] = (packet, time.time(), data)  # Track the packet
                    self.sequence_number += len(data)  # Update the sequence number

                if not data and not self.unacked_packets:
                    # Exit the loop if all data has been sent and acknowledged
                    break

                try:
                    # Set a timeout to wait for ACKs
                    timeout = max(min(self.get_timeout(), 1.0), 0.1)
                    self.sock.settimeout(timeout)
                    ack_packet, _ = self.sock.recvfrom(self.PACKET_SIZE)  # Receive ACK packet
                    ack_seq = struct.unpack('>i', ack_packet[:self.SEQ_ID_SIZE])[0]  # Extract sequence number from ACK

                    if ack_seq > min(self.unacked_packets.keys()):
                        current_time = time.time()
                        bytes_acked = 0

                        for seq in list(self.unacked_packets.keys()):
                            if seq < ack_seq:
                                _, send_time, data = self.unacked_packets[seq]
                                delay = current_time - send_time  # Calculate packet delay
                                bytes_acked += len(data)

                                # Update RTT and calculate jitter
                                self.update_rtt(delay)
                                self.packet_delays.append(delay)
                                if self.last_delay is not None:
                                    jitter = abs(delay - self.last_delay)
                                    self.jitters.append(jitter)
                                self.last_delay = delay

                                total_bytes += len(data)  # Update total bytes sent
                                del self.unacked_packets[seq]  # Remove acknowledged packet

                        # Estimate bandwidth and adjust window based on feedback
                        self.estimate_bandwidth(bytes_acked, current_time - send_time)
                        self.adjust_window(True, bytes_acked, delay)

                except socket.timeout:
                    # Handle timeout (packet loss)
                    self.adjust_window(False)
                    if self.unacked_packets:
                        # Retransmit the oldest unacknowledged packet
                        oldest_seq = min(self.unacked_packets.keys())
                        packet = self.unacked_packets[oldest_seq][0]
                        self.sock.sendto(packet, self.server_addr)
                        self.unacked_packets[oldest_seq] = (packet, time.time(), self.unacked_packets[oldest_seq][2])

        # Send an empty packet to signal the end of the transmission
        empty_packet = self.create_packet(b'')
        self.sock.sendto(empty_packet, self.server_addr)

        try:
            # Wait for final acknowledgments and FIN signal
            self.sock.settimeout(1.0)
            self.sock.recvfrom(self.PACKET_SIZE)  # ACK
            self.sock.recvfrom(self.PACKET_SIZE)  # FIN
            finack_packet = self.create_packet(b'==FINACK==')  # Send FINACK to complete the connection.
            self.sock.sendto(finack_packet, self.server_addr)
        except socket.timeout:
            pass  # If no response, end the transmission

        total_time = time.time() - start_time  # Calculate total time taken
        throughput = total_bytes / total_time if total_time > 0 else 0  # Calculate throughput in bytes per second
        avg_delay = sum(self.packet_delays) / len(self.packet_delays) if self.packet_delays else 0  # Average delay
        avg_jitter = sum(self.jitters) / len(self.jitters) if self.jitters else 0  # Average jitter

        return throughput, avg_delay, avg_jitter  # Return the calculated metrics

    def close(self):
        # Close the socket to release resources
        self.sock.close()

def main():
    FILE_PATH = "./docker/file.mp3"  # Define the path to the file to be sent

    sender = OptimizedAdaptiveSender()  # Create an instance of OptimizedAdaptiveSender
    try:
        throughput, delay, jitter = sender.send_file(FILE_PATH)  # Send the file and get performance metrics
        # Calculate the overall metric based on throughput, delay, and jitter
        metric = 0.2 * (throughput / 2000) + 0.1 / jitter + 0.8 / delay
        print(f"{throughput:.7f},{delay:.7f},{jitter:.7f},{metric:.7f}")  # Print the metrics
    finally:
        sender.close()  # Close the sender to release resources

if __name__ == "__main__":
    main()  # Execute the main function to start the program
