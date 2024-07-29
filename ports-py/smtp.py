import ports
import socket as socketlib
import smtplib

smtp_suite = ports.suite("specs/smtp.ports")

sockets = []

@smtp_suite.placeholder("create-socket")
def create_socket(env):
    "Open a server socket to read from"
    try:
        server_socket = socketlib.socket(socketlib.AF_INET, socketlib.SOCK_STREAM)
        server_socket.setblocking(True)
        server_socket.bind(("localhost", 0))
        server_socket.listen(1)
        sockets.append(server_socket)
        return server_socket
    except Exception as err:
        return err
    
@smtp_suite.placeholder("socket-accept")
def socket_accept(env, server_socket: socketlib.socket):
    "Accept a connection from a client"
    try:
        client_socket, address = server_socket.accept()
        sockets.append(client_socket)
        return client_socket
    except Exception as err:
        return err
    
@smtp_suite.placeholder("socket-port")
def socket_port(env, socket):
    "Return the port number of the socket"
    return socket.getsockname()[1]

@smtp_suite.placeholder("socket-receive")
def socket_read(env, socket):
    "Read from the socket"
    return socket.recv(4096)

@smtp_suite.placeholder("socket-write")
def socket_write(env, socket, content):
    socket.sendall(content.encode(encoding="utf-8"))

@smtp_suite.placeholder("smtp-connect")
def smtp_connect(env, host, port):
    return smtplib.SMTP(host, port)

@smtp_suite.tearDown()
def tear_down(env):
    for socket in sockets:
        socket.close()
    sockets.clear()

smtp_suite.run()