import socket
import sys

active_connections = {}

# checks if a port is already in use
def port_used(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("localhost", port))
        except socket.error as e:
            return True
        else:
            return False

# if port 60 is already in use, abort the program
if not port_used(60):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_address = ('', 60)  # Listen on all available network interfaces
    server_socket.bind(server_address)
    server_socket.listen(1)
    print("Listening on port 60...")

    while True:
        # connect and receive data from client
        client_socket, client_address = server_socket.accept()
        data = client_socket.recv(4096).decode('ISO-8859-1')

        if client_address in active_connections:
            # Client already has an active connection, send data
            active_socket = active_connections[client_address]
            active_socket.sendall(data.encode('ISO-8859-1'))
        else:
            # New client connection, store in active_connections dictionary
            active_connections[client_address] = client_socket
            print("TOTAL CONNECTED:", len(active_connections))
            print("CLIENT CONNECTED:", client_address[1])
            print("CLIENT DATA:", data)

        # Receive response from client
        response = client_socket.recv(4096).decode('ISO-8859-1')
        print("CLIENT RESPONSE:", response)

        # Handle disconnection
        if not response:
            del active_connections[client_address]
            client_socket.close()
            print("CLIENT DISCONNECTED:", client_address[1])
            print("TOTAL CONNECTED:", len(active_connections))

else:
    print("Port 60 is already in use.")
    exit()
