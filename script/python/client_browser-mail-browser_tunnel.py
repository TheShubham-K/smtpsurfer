import select
import socket
import sys
import subprocess
import time


# array for all received requests
requests = []


# checks if a port is already in use
def check_port(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("localhost", port))
        except socket.error as e:
            return True
        else:
            return False


# receive data on a port
def receive_data_on_port(port):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_address = ("localhost", port)
    server_socket.bind(server_address)
    server_socket.listen(5)

    print(f"Waiting for connections on port {port}...")

    client_sockets = [server_socket]

    while True:
        # multiplex input/output connections
        readable, _, _ = select.select(client_sockets, [], [])

        for sock in readable:
            if sock == server_socket:
                # new client
                connection, client_address = server_socket.accept()
                print(f"CONNECT CLIENT: {client_address}")
                client_sockets.append(connection)
            else:
                # data from a connected client
                data = sock.recv(1024)
                if data:
                    # print(f"RECEIVE DATA FROM CLIENT: {sock.getpeername()}:\n{data.decode()}")
                    # hand over data to sendmail
                    # format of mailtext:
                    # PORT=
                    # <port>
                    # BODY=
                    # <body>
                    mailtext = ""
                    mailtext += "PORT=\n"
                    mailtext += str(sock.getpeername()[1]) + "\n"
                    mailtext += "BODY=\n"
                    mailtext += data.decode()
                    # print(f"{mailtext}")
                    requests.append(mailtext)
                    # subprocess.run(["sendmail", "-i", "smtpsurfer@mailproxy"], input=mailtext.encode())
                else:
                    print(f"DISCONNECT CLIENT: {sock.getpeername()}")
                    sock.close()
                    client_sockets.remove(sock)


# read data from stdin
def read_stdin():
    response = ""
    while True:
        data = sys.stdin.readline().strip()
        if data:
            response += data + "\n"
        else:
            break
    print(f"RECEIVED DATA FROM STDIN:\n{response}")
    sys.stdin.close()
    # split string: take line after PORT= and all lines after BODY=
    port = response.split("PORT=\n")[1].split("\n")[0]
    body = "\n".join(response.split("BODY=\n")[1:])
    print(f"PORT= {port}")
    print(f"BODY=\n{body}")
    # send data to port
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect(("localhost", int(port)))
        s.sendall(body.encode())


def send_requests():
    while True:
        requests_in_queue = len(requests)
        if requests:
            print(f"REQUESTS IN QUEUE: {requests_in_queue}")
            request = requests.pop(0)
            print(f"SEND REQUEST:\n{request}")
            subprocess.run(
                ["sendmail", "-i", "smtpsurfer@mailproxy"], input=request.encode()
            )
        time.sleep(1)


if __name__ == "__main__":
    import threading

    # thread: receive_data_on_port
    # check if port 60 is already in use
    if not check_port(60):
        port_thread = threading.Thread(target=receive_data_on_port, args=(60,))
        port_thread.start()
    else:
        print("Port 60 is already in use. Only stdin is available.")

    # thread: send_requests
    send_thread = threading.Thread(target=send_requests)
    send_thread.start()

    # mainthread: read_stdin function in the main thread
    read_stdin()
