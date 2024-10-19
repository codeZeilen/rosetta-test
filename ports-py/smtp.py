import ports
import socket as socketlib
import smtplib

smtp_suite = ports.suite("suites/smtp.ports")

sockets = []

@smtp_suite.placeholder("create-socket")
def create_socket(env):
    "Open a server socket to read from"
    try:
        server_socket = socketlib.socket(socketlib.AF_INET, socketlib.SOCK_STREAM)
        server_socket.setblocking(True)
        server_socket.bind(("127.0.0.1", 0))
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
    assert socket.fileno() != -1 # Socket not closed
    return socket.getsockname()[1]

@smtp_suite.placeholder("socket-receive")
def socket_read(env, socket):
    "Read from the socket"
    assert socket.fileno() != -1 # Socket not closed
    result = socket.recv(4096).decode(encoding="ascii")
    return result

@smtp_suite.placeholder("socket-write")
def socket_write(env, socket: socketlib.socket, content):
    assert socket.fileno() != -1 # Socket not closed
    socket.sendall(content.encode(encoding="ascii"))
    
@smtp_suite.placeholder("socket-close")
def socket_close(env, socket):
    socket.close()

@smtp_suite.placeholder("smtp-connect")
def smtp_connect(env, host, port):
    return smtplib.SMTP(host, port)

@smtp_suite.placeholder("smtp-disconnect")
def smtp_disconnect(env, smtp):
    smtp.close()

@smtp_suite.placeholder("smtp-ehlo")
def smtp_ehlo(env, smtp, content):
    return smtp.ehlo(content)

@smtp_suite.placeholder("smtp-response-code")
def smtp_response_code(env, smtp_response):
    return smtp_response[0]

@smtp_suite.placeholder("smtp-response-message")
def smtp_response_message(env, smtp_response):
    return (smtp_response[1]).decode(encoding="ascii")

@smtp_suite.placeholder("smtp-extensions")
def smtp_capabilities(env, smtp, ehlo_response):
    return map(str.strip, smtp_response_message(env, ehlo_response).split("\n")[1:])

@smtp_suite.placeholder("smtp-authenticate")
def smtp_authenticate(env, smtp, method, credentials):
    result = False
    if method in ("PLAIN", "XOAUTH2", "CRAM-MD5", "LOGIN"):
        try:
            smtp.login(*credentials)
            result = True
        except Exception as err:
            result = err
    return result

@smtp_suite.placeholder("smtp-auth-successful?")
def smtp_auth_successful(env, result):
    return result == True

@smtp_suite.placeholder("smtp-auth-credentials-error?")
def smtp_auth_credentials_error(env, result):
    return type(result) == smtplib.SMTPAuthenticationError

@smtp_suite.placeholder("smtp-auth-not-supported-error?")
def smtp_auth_not_supported_error(env, result):
    return type(result) == smtplib.SMTPNotSupportedError

@smtp_suite.placeholder("smtp-mail")
def smtp_mail(env, smtp, sender):
    return smtp.mail(sender)

@smtp_suite.placeholder("smtp-rcpt")
def smtp_rcpt(env, smtp, recipients, option_tuples):
    if option_tuples:
        options = list(map(lambda o: env["compile-options-strings"](o), option_tuples))
    else:
        options = [[]] * len(recipients)
    return list(map(lambda recipient_options: smtp.rcpt(recipient_options[0],options=recipient_options[1]), zip(recipients, options)))

@smtp_suite.placeholder("smtp-rset")
def smtp_rset(env, smtp):
    return smtp.rset()

@smtp_suite.placeholder("smtp-send-message")
def smtp_rset(env, smtp: smtplib.SMTP, message, sender, recipients):
    responses_dict = smtp.sendmail(sender, recipients, message)
    return map(lambda r: responses_dict[r] if r in responses_dict else (250, ''), recipients)
     
@smtp_suite.tearDown()
def tear_down(env):
    for socket in sockets:
        socket.close()
    sockets.clear()

smtp_suite.run(exclude_capabilities=("root.commands.auth.xoauth2",))#only=("test_plain_auth_unsuccessful",))