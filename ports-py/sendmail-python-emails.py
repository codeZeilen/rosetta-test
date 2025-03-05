import ports
import socket as socketlib
import ssl
import emails
from emails.backend.smtp import SMTPBackend

sendmail_suite = ports.suite("suites/sendmail.ports")


#
# Suite Lifecycle
#

@sendmail_suite.tearDown()
def tear_down(env):
    for socket in sockets:
        socket.close()
    sockets.clear()
    if "activated_8_bit_mime" in env:
        del env["activated_8_bit_mime"]


#
# Sockets
#

sockets = []

@sendmail_suite.placeholder("create-socket")
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
    
@sendmail_suite.placeholder("socket-accept")
def socket_accept(env, server_socket: socketlib.socket):
    "Accept a connection from a client"
    try:
        server_socket.settimeout(0.5)
        client_socket, address = server_socket.accept()
        sockets.append(client_socket)
        return client_socket
    except Exception as err:
        if(isinstance(err,TimeoutError)):
            raise err
        else:
            return err
    
@sendmail_suite.placeholder("secure-server-socket-wrap")
def secure_server_socket_wrap(env, connection, ca_file, cert_file, key_file, close_wrapped_socket):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    context.load_cert_chain(ports.fixture_path(ca_file), ports.fixture_path(key_file))
    try:
        ssock = context.wrap_socket(connection, server_side=True)
        sockets.append(ssock)
        return ssock
    except Exception as err:
        return err
        
@sendmail_suite.placeholder("socket-port")
def socket_port(env, socket):
    "Return the port number of the socket"
    assert socket.fileno() != -1, "Tried to get the port of an already closed socket"
    return socket.getsockname()[1]

@sendmail_suite.placeholder("socket-receive")
def socket_read(env, socket : socketlib.socket):
    "Read from the socket"
    if(socket.fileno() == -1):
        return ""
    result = socket.recv(4096).decode(encoding="utf-8")
    return result

@sendmail_suite.placeholder("socket-write")
def socket_write(env, socket: socketlib.socket, content):
    assert socket.fileno() != -1, "Tried to write on an already closed socket"
    socket.sendall(content.encode(encoding="utf-8"))
    
@sendmail_suite.placeholder("socket-close")
def socket_close(env, socket):
    socket.close()
    

#
# SMTP connection
#

@sendmail_suite.placeholder("smtp-connect")
def smtp_connect(env, host, port):
    return SMTPBackend(host=host, port=port)
    
@sendmail_suite.placeholder("smtp-connect-with-auto-starttls")
def smtp_connect_with_auto_starttls(env, host, port, automatic_mode):
    pass

@sendmail_suite.placeholder("smtp-secure-connect")
def smtp_secure_connect(env, host, port, cafile):
    pass

@sendmail_suite.placeholder("smtp-secure-connect-with-timeout")
def smtp_secure_connect_with_timeout(env, host, port, cafile, timeout=None):
    pass
    # context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    # context.check_hostname = False
    # context.verify_mode = ssl.CERT_NONE
    # context.load_verify_locations(ports.fixture_path(cafile))
    # if timeout:
    #     try:
    #         result = smtplib.SMTP_SSL(host, port, context=context, timeout=float(timeout))
    #     except TimeoutError as err:
    #         return err
    # else:
    #     result = smtplib.SMTP_SSL(host, port, context=context)
    # if isinstance(result, ssl.SSLError):
    #     raise result
    # else:
    #     return result

@sendmail_suite.placeholder("smtp-disconnect")
def smtp_disconnect(env, sender):
    sender.close()
    
@sendmail_suite.placeholder("smtp-connected?")
def smtp_connected(env, sender):
    pass


#
# Send Message
#

@sendmail_suite.placeholder("smtp-send-message-with-options")
def smtp_send_message(env, sender:SMTPBackend, message, sender_address, recipient_addresses, message_options, recipients_options):
    try:
        message = emails.Message(text=message,
                                 subject="Test",
                                 mail_to=recipient_addresses,
                                 mail_from=sender_address)
        return [message.send(smtp=sender)]
    except Exception as e:
        return [e]     
    
#
# Response Accessors
# 

@sendmail_suite.placeholder("send-success?")
def sendmail_success(env, result):
    return (not isinstance(result, Exception)) and result.status_code == 250

@sendmail_suite.placeholder("send-error?")
def sendmail_error(env, result):
    return isinstance(result, Exception) or result.status_code != 250


#
# Running
#

# they do mitigation for addresses but detection for other fields

sendmail_suite.run(#only_capabilities=("root.send-message",),
                   exclude_capabilities=(
                       "root.connection",
                       "root.crlf-injection-detection.send-message.detection",
                       "root.8bitmime.send-message.mandatory-options",
                       "root.smtputf8.send-message.mandatory-options"),
                   expected_failures=(
                       # The library should problably automatically detect whether 8bitmime is required
                       "test_non-ascii_content_in_send-message_with_8BITMIME_support",
                       "test_non-ascii_content_in_send-message_without_8BITMIME_support",
                       # Same with smtputf8
                       "test_international_sender_mailbox_in_send-message_with_SMTPUTF8_support",
                       "test_international_recipient_mailbox_in_send-message_with_SMTPUTF8_support",
                       "test_Send_a_message_with_empty_recipient",))