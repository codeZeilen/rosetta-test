import ports
import socket as socketlib
import ssl
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
    
@smtp_suite.placeholder("secure-server-socket-wrap")
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
        
@smtp_suite.placeholder("socket-port")
def socket_port(env, socket):
    "Return the port number of the socket"
    assert socket.fileno() != -1, "Tried to get the port of an already closed socket"
    return socket.getsockname()[1]

@smtp_suite.placeholder("socket-receive")
def socket_read(env, socket : socketlib.socket):
    "Read from the socket"
    assert socket.fileno() != -1, "Tried to read from an already closed socket"
    result = socket.recv(4096).decode(encoding="utf-8")
    return result

@smtp_suite.placeholder("socket-write")
def socket_write(env, socket: socketlib.socket, content):
    assert socket.fileno() != -1, "Tried to write on an already closed socket"
    socket.sendall(content.encode(encoding="utf-8"))
    
@smtp_suite.placeholder("socket-close")
def socket_close(env, socket):
    socket.close()

@smtp_suite.placeholder("smtp-connect")
def smtp_connect(env, host, port):
    try:
        return smtplib.SMTP(host, port)
    except Exception as e:
        return e
    
@smtp_suite.placeholder("smtp-connected?")
def smtp_connected(env, smtp: smtplib.SMTP):
    return not smtp.sock is None
    
@smtp_suite.placeholder("smtp-quit")
def smtp_quit(env, smtp: smtplib.SMTP):
    return smtp.quit()

@smtp_suite.placeholder("smtp-connect-with-auto-starttls")
def smtp_connect_with_auto_starttls(env, host, port, automatic_mode):
    pass

@smtp_suite.placeholder("smtp-secure-connect")
def smtp_secure_connect(env, host, port, cafile):
    return smtp_secure_connect_with_timeout(env, host, port, cafile)

@smtp_suite.placeholder("smtp-secure-connect-with-timeout")
def smtp_secure_connect_with_timeout(env, host, port, cafile, timeout=None):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    context.load_verify_locations(ports.fixture_path(cafile))
    if timeout:
        try:
            result = smtplib.SMTP_SSL(host, port, context=context, timeout=timeout)
        except TimeoutError as err:
            return err
    else:
        result = smtplib.SMTP_SSL(host, port, context=context)
    if isinstance(result, ssl.SSLError):
        raise result
    else:
        return result

@smtp_suite.placeholder("smtp-disconnect")
def smtp_disconnect(env, smtp):
    smtp.close()

@smtp_suite.placeholder("smtp-ehlo")
def smtp_ehlo(env, smtp, content):
    try:
        return smtp.ehlo(content)
    except ValueError as e:
        return e

@smtp_suite.placeholder("smtp-response-code")
def smtp_response_code(env, smtp_response):
    if isinstance(smtp_response, smtplib.SMTPResponseException):
        return smtp_response.smtp_code
    else:
        return smtp_response[0]

@smtp_suite.placeholder("smtp-response-message")
def smtp_response_message(env, smtp_response):
    if isinstance(smtp_response, smtplib.SMTPResponseException):
        return smtp_response.smtp_error
    else:
        return (smtp_response[1]).decode(encoding="ascii")
    
    

@smtp_suite.placeholder("smtp-extensions")
def smtp_capabilities(env, smtp: smtplib.SMTP, ehlo_response):
    return smtp.esmtp_features.keys()

@smtp_suite.placeholder("smtp-authenticate-initial-response")
def smtp_authenticate(env, smtp : smtplib.SMTP, method, credentials, initial_response):
    result = False
    if method in ("PLAIN", "XOAUTH2", "CRAM-MD5", "LOGIN"):
        try:
            smtp.login(*credentials, initial_response_ok=initial_response)
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

@smtp_suite.placeholder("smtp-extension-not-supported-error?")
def smtp_extension_not_supported_error(env, result):
    return type(result) == smtplib.SMTPNotSupportedError

@smtp_suite.placeholder("smtp-mail-with-options")
def smtp_mail(env, smtp, sender, options=()):
    try:
        return smtp.mail(sender, options=options)
    except ValueError as err:
        return err
    except smtplib.SMTPNotSupportedError as err:
        return err

@smtp_suite.placeholder("smtp-rcpt")
def smtp_rcpt(env, smtp, recipients, option_tuples):
    if option_tuples:
        options = list(map(lambda o: env["compile-options-strings"](o), option_tuples))
    else:
        options = [[]] * len(recipients)
    
    try:
        return list(map(lambda recipient_options: smtp.rcpt(recipient_options[0],options=recipient_options[1]), zip(recipients, options)))
    except ValueError as err:
        return [err]
    except smtplib.SMTPNotSupportedError as err:
        return [err]

@smtp_suite.placeholder("smtp-rset")
def smtp_rset(env, smtp):
    return smtp.rset()

@smtp_suite.placeholder("smtp-vrfy")
def smtp_vrfy(env, smtp : smtplib.SMTP, user):
    try:
        return smtp.vrfy(user)
    except ValueError as e:
        return e
    
@smtp_suite.placeholder("smtp-help")
def smtp_help(env, smtp: smtplib.SMTP, command):
    try:
        # We have to manually construct a reply tuple, as
        # .help only returns the help text, in contrast to all
        # other low-level SMTP command methods.
        return (250, smtp.help(command))
    except Exception as e:
        return e
    
@smtp_suite.placeholder("smtp-expn")
def smtp_expn(env, smtp : smtplib.SMTP, list_name):
    try:
        return smtp.expn(list_name)
    except Exception as e:
        return e

@smtp_suite.placeholder("smtp-expn-response-users-list")
def smtp_expn_response_users_list(env, expn_response):
    return expn_response[1].decode("utf-8").split("\n")

@smtp_suite.placeholder("smtp-data")
def smtp_data(env, smtp: smtplib.SMTP, content):
    try:
        return smtp.data(content)
    except smtplib.SMTPDataError as err:
        return err
    
@smtp_suite.placeholder("smtp-starttls")
def smtp_starttls(env, smtp, certfile=None, keyfile=None):
    if certfile and keyfile:
        return smtp.starttls(keyfile=ports.fixture_path(keyfile), certfile=ports.fixture_path(certfile))
    else:
        try:
            return smtp.starttls()
        except smtplib.SMTPNotSupportedError as err:
            return err

@smtp_suite.placeholder("smtp-send-message-with-options")
def smtp_send_message(env, smtp: smtplib.SMTP, message, sender, recipients, message_options, recipients_options):
    try:
        responses_dict = smtp.sendmail(sender, recipients, message, mail_options=message_options, rcpt_options=recipients_options)
    except smtplib.SMTPDataError as err:
        return [err]
    except smtplib.SMTPResponseException as err:
        return [(err.smtp_code, err.smtp_error)]
    except smtplib.SMTPNotSupportedError as err:
        return [err]
    except UnicodeEncodeError as err:
        return [err]
    except smtplib.SMTPRecipientsRefused as err:
        return list(err.recipients.values())
    return list(map(lambda r: responses_dict[r] if r in responses_dict else (250, ''), recipients))
     
@smtp_suite.placeholder("smtp-error?")
def smtp_error(env, result):
    return isinstance(result, Exception)
     
@smtp_suite.tearDown()
def tear_down(env):
    for socket in sockets:
        socket.close()
    sockets.clear()

#smtp_suite.run(only=("test_international_mailbox_in_rcpt_with_SMTPUTF8_support",))
smtp_suite.run(
        exclude_capabilities=(
            "root.commands.auth.xoauth2",
            "root.commands.automatic-starttls",
            "root.smtputf8.mail.automatic-smtputf8-detection",
            "root.smtputf8.send-message.automatic-smtputf8-detection",
            "root.crlf-injection-detection.commands.detection.mail",
            "root.crlf-injection-detection.commands.mitigation.ehlo",
            "root.crlf-injection-detection.send-message.detection"), 
        exclude=(
            "test_CRLF_detection_in_RCPT_command_-_recipient",
            "test_CRLF_mitigation_in_RCPT_command_-_options",
            "test_CRLF_detection_in_VRFY_command",
            "test_CRLF_mitigation_in_HELP_command",
            "test_CRLF_detection_in_EXPN_command",
            "test_Handle_421_during_data_command"))
#smtp_suite.run(only_capabilities=("root.commands.starttls"))# ("test_starttls","test_starttls_without_server_support","test_After_starttls_extensions_need_to_be_refetched",))
