import rosetta
import socket as socketlib
import ssl
import emails
from emails.backend.smtp import SMTPBackend
from emails.backend.response import SMTPResponse

sendmail_suite = rosetta.suite("rosetta-test-suites/sendmail.ros")


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
    context.load_cert_chain(rosetta.fixture_path(ca_file), rosetta.fixture_path(key_file))
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

@sendmail_suite.placeholder("sendmail-connect")
def sendmail_connect(env, host, port):
    backend = SMTPBackend(host=host, port=port)
    return backend
    
@sendmail_suite.placeholder("sendmail-connect-with-credentials")
def sendmail_connect_with_credentials(env, host, port, username, password):
    backend = SMTPBackend(host=host, port=port, user=username, password=password)
    return backend

@sendmail_suite.placeholder("sendmail-disconnect")
def sendmail_disconnect(env, sender):
    if not isinstance(sender, SMTPBackend):
        return sender
    sender.close()
    
@sendmail_suite.placeholder("sendmail-connected?")
def sendmail_connected(env, backend):
    return backend._client is not None and backend._client.sock is not None


#
# Send Message
#

@sendmail_suite.placeholder("sendmail-send-message-full")
def sendmail_send_message(env, sender:SMTPBackend, message, sender_address, recipient_addresses, cc_addresses, bcc_addresses, custom_headers, attachments, message_options, recipients_options):
    try:
        message = emails.Message(text=message,
                                 subject="Test",
                                 mail_to=recipient_addresses,
                                 mail_from=sender_address,
                                 cc=cc_addresses,
                                 bcc=bcc_addresses,
                                 headers=custom_headers,)
        for attachment in attachments:
            message_properties = {
                "content_disposition": attachment["content-disposition"],
            }            
            
            if "file-name" in attachment:
                message_properties["filename"] = attachment["file-name"]
            
            read_mode = "r"
            if attachment["data"].endswith(".png"):
                read_mode = "rb"    
            message_properties["data"] = open(rosetta.fixture_path('sendmail-fixtures/' + attachment["data"]), read_mode)
            
            if "content-type" in attachment:
                message_properties["content_type"] = attachment["content-type"]
            
            message.attach(**message_properties)
        return [message.send(smtp=sender,smtp_mail_options=message_options, smtp_rcpt_options=recipients_options)]
    except Exception as e:
        return [e]     
    
#
# Response Accessors
# 

@sendmail_suite.placeholder("send-success?")
def sendmail_success(env, result):
    return (not isinstance(result, Exception)) and result.status_code == 250

@sendmail_suite.placeholder("send-error?")
def sendmail_error(env, result: SMTPResponse):
    return isinstance(result, Exception) or result.status_code != 250 or result.error is not None


#
# Running
#

# python-emails does mitigation for addresses but detection for other fields

sendmail_suite.run(
    exclude=(
        # python-emails does not support attachments without a name
        "test_attachment_without_a_name",),
    exclude_capabilities=(
        "root.connection.lazy-connection", # TODO: python-emails does not handle failed auth correctly
        "root.connection.eager-connection",
        "root.general-crlf-injection.detection",
        "root.headers.crlf-injection.mitigation",
        "root.unicode-messages.8bitmime.automatic-detection",
        "root.internationalized-email-addresses.smtputf8.explicit-options"),
    expected_failures=(
        "test_non-ascii_content_in_send-message_with_8BITMIME_option_and_without_8BITMIME_server_support", # 8bitmime or smtputf8 should not be sent when server does not support it
        "test_non-ascii_content_in_send-message_with_8BITMIME_option_and_server_support", # 8bitmime is sent but body is not 8bitmime
        "test_Handle_421_at_start_of_data_command",
        "test_Handle_421_during_data_command",
        # The library should problably automatically detect whether smtputf8 is required
        "test_international_sender_mailbox_in_send-message_with_SMTPUTF8_support",
        "test_international_recipient_mailbox_in_send-message_with_SMTPUTF8_support",
        "test_Send_a_message_with_empty_recipient",
        "test_set_header_with_unicode_value")) # Encoding of unicode in header value seems wrong (underscore instead of space)