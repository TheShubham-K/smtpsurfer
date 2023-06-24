import socket
import signal
import sys
import time

# Global variable to hold the server socket
server_socket = None
MAX_DATA_RECV = 8 * 1024 * 1024  # 8MB
CHUNK_SIZE = 8 * 1024 * 1024  # 8MB
RESPONSE_TIMEOUT = 4  # Maximum wait time for response in seconds

def signal_handler(sig, frame):
    # Cleanup actions
    server_socket.close()
    print("Terminating...")
    sys.exit(0)

def port_used(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("localhost", port))
        except socket.error:
            return True
        else:
            return False

# Register signal handler for Ctrl+C
signal.signal(signal.SIGINT, signal_handler)

if not port_used(70):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_address = ('', 70)
    server_socket.bind(server_address)
    server_socket.listen(1)
    print("Listening on port 70...")

    while True:
        try:
            client_socket, client_address = server_socket.accept()
            print("CLIENT CONNECTED:", client_address[1])

            while True:
                data = client_socket.recv(4096).decode('ISO-8859-1')
                if not data:
                    break

                preview_client_data = data[:1000]
                print("CLIENT DATA:", preview_client_data, "...")
                print("\n")

                # Send data to localhost:8080 and receive response
                response = ''
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as proxy_socket:
                    try:
                        proxy_socket.connect(("localhost", 8080))
                        proxy_socket.sendall(data.encode('ISO-8859-1'))

                        # Receive response in chunks and wait for a maximum of RESPONSE_TIMEOUT seconds
                        proxy_socket.settimeout(RESPONSE_TIMEOUT)
                        chunk_count = 0
                        while True:
                            print("RESPONSE CHUNK", chunk_count)
                            chunk = proxy_socket.recv(CHUNK_SIZE).decode('ISO-8859-1')
                            if not chunk:
                                break
                            response += chunk
                            chunk_count += 1
                    except socket.error as e:
                        print("Failed to send data to localhost:8080:", e)

                # Preview response 20 chars
                preview_response = response[:1000]
                print("RESPONSE:", preview_response, "...")
                print("\n")

                # Send response back to the client
                client_socket.sendall(response.encode('ISO-8859-1'))

            client_socket.close()

        except KeyboardInterrupt:
            signal_handler(signal.SIGINT, None)

else:
    print("Port 70 is already in use.")
    exit()
