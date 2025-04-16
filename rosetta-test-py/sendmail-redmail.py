import rosetta
import socket as socketlib
import ssl
from redmail import EmailSender
import pathlib
import smtplib

sendmail_suite = rosetta.suite("rosetta-test-suites/sendmail.ros")


#
# Suite Lifecycle
#

@sendmail_suite.tearDown()
def tear_down(env):
    for socket in sockets:
        socket.close()
    sockets.clear()


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
    try:
        sender = EmailSender(host=host, port=port, use_starttls=False)
        sender.connect()
        return sender
    except Exception as e:
        sender.close()
        return e
    
@sendmail_suite.placeholder("sendmail-connect-with-credentials")
def sendmail_connect_with_credentials(env, host, port, username, password):
    try:
        sender = EmailSender(host=host, port=port, username=username, password=password)
        sender.connect()
        return sender
    except Exception as e:
        sender.close()
        return e

@sendmail_suite.placeholder("sendmail-disconnect")
def sendmail_disconnect(env, sender):
    if not isinstance(sender, EmailSender):
        return sender
    try:
        sender.close()
    except smtplib.SMTPServerDisconnected:
        pass # We are good apparently
    
@sendmail_suite.placeholder("sendmail-connected?")
def sendmail_connected(env, sender: EmailSender):
    return isinstance(sender, EmailSender) and sender.is_alive


#
# Send Message
#

@sendmail_suite.placeholder("sendmail-send-message-full")
def sendmail_send_message(env, sender: EmailSender, message, sender_address, recipient_addresses, cc_addresses, bcc_addresses, custom_headers, attachments, message_options, recipients_options):
    try:
        redmail_attachments = {
            attachment["file-name"]: pathlib.Path(rosetta.fixture_path('sendmail-fixtures/' + attachment["data"])) 
                for attachment in attachments 
                if attachment["content-disposition"] == "attachment"}  
        sender.send(sender=sender_address,
                       receivers=recipient_addresses,
                       cc=cc_addresses,
                       bcc=bcc_addresses,  
                       headers=custom_headers,
                       subject="test",
                       text=message,
                       attachments=redmail_attachments)
    except Exception as e:
        return [e]
    return [True] # EmailSender.send does not return anything related to the sending
     
    
#
# Response Accessors
# 

@sendmail_suite.placeholder("send-success?")
def sendmail_success(env, result):
    return not isinstance(result, Exception)

@sendmail_suite.placeholder("send-error?")
def sendmail_error(env, result):
    return isinstance(result, Exception)


#
# Running
#

#sendmail_suite.run(only=("test_basic_image_attachment",))

sendmail_suite.run(
    exclude=(
        # redmail does not support inline disposition
        "test_text_attachment_with_inline_disposition", 
        "test_image_attachment_with_inline_disposition",
        
        # redmail does not support attachments without a filename
        "test_attachment_without_a_name",
        
        # redmail does not support multiple attachments with the same name
        "test_multiple_attachments_with_same_name",
        
        "test_CRLF_detection_in_send-message_recipient", 
        "test_CRLF_mitigation_in_send-message_sender",
        "test_Connect_with_invalid_credentials"), # TODO redmail leaks sockets when credentials are invalid
    exclude_capabilities=(
        "root.unicode-messages.8bitmime.automatic-detection",
        "root.unicode-messages.8bitmime.mandatory-options",
        "root.internationalized-email-addresses.smtputf8.explicit-options",
        "root.headers.crlf-injection.mitigation",), # redmail does detects CRLF injections in header values
    expected_failures=(
        "test_Handle_421_during_data_command",
        "test_Handle_421_at_start_of_data_command",
        "test_Handle_421_at_the_end_of_data_command",
        "test_Handle_421_during_rcpt_command",
        "test_Handle_421_during_mail_command",))