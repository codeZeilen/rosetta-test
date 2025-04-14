require_relative "rosetta"
require "socket"
require "net/smtp"
require "openssl"

suite "rosetta-test-suites/smtp.rosetta" do
  only_capabilities "root.connection", "root.commands"

  exclude_capabilities "root.commands.expn",
    "root.commands.help",
    "root.commands.vrfy",
    "root.commands.auth.xoauth2",
    "root.commands.automatic-starttls"

  expected_failures "test_starttls_without_server_support",
    "test_plain_auth_not_supported"

  placeholder "create-socket" do |env|
    TCPServer.new(0)
  rescue => e
    e
  end

  placeholder "socket-receive" do |env, socket|
    socket.recvfrom(4096).first
  end

  placeholder "socket-write" do |env, socket, data|
    socket.write(data)
  end

  placeholder "socket-port" do |env, socket|
    socket.addr[1]
  end

  placeholder "socket-accept" do |env, socket|
    client, _addrinfo = socket.accept
    client
  end

  placeholder "socket-close" do |env, socket|
    socket.close
  end

  placeholder "secure-server-socket-wrap" do |env, socket, ca_file, cert_file, key_file, close_underlying_socket|
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.ca_file = fixture_path(ca_file)
    ctx.cert = fixture_path(cert_file)
    ctx.key = fixture_path(key_file)

    ssl_socket = OpenSSL::SSL::SSLServer.new(socket, ctx)
    ssl_socket.start_immediately = true
    ssl_socket.to_io
  end

  placeholder "smtp-connect" do |env, host, port|
    Net::SMTP.start(host, port)
  rescue => e
    e
  end

  placeholder "smtp-connect-with-auto-starttls" do |env, host, port, starttls_mode|
    # TODO: doesn't work yet
    mode = case starttls_mode
    when :automatic
      :auto
    when :required
      :always
    when :never
      false
    else
      raise "Unknown starttls_mode: #{starttls_mode}"
    end

    Net::SMTP.start(host, port, starttls: mode)
  rescue => e
    e
  end

  placeholder "smtp-secure-connect" do |env, host, port, ca_file|
    raise Test::Unit::AssertionFailedError, "Placeholder not implemented: smtp-secure-connect"
  end

  placeholder "smtp-secure-connect-with-timeout" do |env, host, port, ca_file, timeout|
    raise Test::Unit::AssertionFailedError, "Placeholder not implemented: smtp-secure-connect-with-timeout"
  end

  placeholder "smtp-disconnect" do |env, connection|
    connection.finish
  rescue => e
    e
  end

  placeholder "smtp-connected?" do |env, connection|
    connection.started?
  end

  placeholder "smtp-ehlo" do |env, connection, content|
    connection.ehlo(content)
  rescue => e
    e
  end

  def address_with_options_list(address, options)
    opts = if options.nil?
      {}
    else
      options.map do |option|
        key, value = option
        value = value.join(",") if value.is_a?(Array)
        [key.to_sym, value]
      end.to_h
    end

    Net::SMTP::Address.new(address, **opts)
  end

  def address_with_options(address, options)
    opts = if options.nil?
      {}
    else
      options.map do |option|
        key, value = option.split("=")
        [key.to_sym, value]
      end.to_h
    end

    Net::SMTP::Address.new(address, **opts)
  end

  placeholder "smtp-mail-with-options" do |env, connection, from, options|
    addr = address_with_options(from, options)
    connection.mailfrom(addr)
  rescue => e
    e
  end

  placeholder "smtp-rcpt" do |env, connection, to_list, options_list|
    to_list.zip(options_list).map do |to, options|
      address = address_with_options_list(to, options)
      connection.rcptto(address)
    rescue => e
      e
    end
  end

  placeholder "smtp-data" do |env, connection, content|
    connection.data(content)
  rescue => e
    e
  end

  placeholder "smtp-rset" do |env, connection|
    connection.rset
  end

  placeholder "smtp-vrfy" do |env, connection, content|
    raise Test::Unit::AssertionFailedError, "Placeholder not implemented: smtp-vrfy"
  end

  placeholder "smtp-help" do |env, connection, content|
    raise Test::Unit::AssertionFailedError, "Placeholder not implemented: smtp-help"
  end

  placeholder "smtp-expn" do |env, connection, content|
    raise Test::Unit::AssertionFailedError, "Placeholder not implemented: smtp-expn"
  end

  placeholder "smtp-starttls" do |env, connection, cert_file, key_file|
    connection.starttls
  end

  placeholder "smtp-quit" do |env, connection|
    connection.quit
  end

  placeholder "smtp-send-message-with-options" do |env, connection, message_content, from, to_list, message_options, to_list_options|
    to_addresses = to_list.zip(to_list_options).map { |addr, opts| address_with_options(addr, opts) }
    connection.send_message(message_content, from, to_addresses)
  rescue => e
    e
  end

  placeholder "smtp-response-code" do |env, response|
    if response.is_a?(Net::SMTPError)
      response.response.status.to_i
    else
      response.status.to_i
    end
  end

  placeholder "smtp-response-message" do |env, response|
    response.string[4..]
  end

  placeholder "smtp-error?" do |env, response|
    response.is_a?(Net::SMTPError) || response.is_a?(SocketError)
  end

  placeholder "smtp-extensions" do |env, connection, ehlo_response|
    connection.capabilities
  end

  placeholder "smtp-extension-not-supported-error?" do |env, response|
    response.is_a?(Net::SMTPUnsupportedCommand)
  end

  placeholder "smtp-expn-response-users-list" do |env, response|
    raise Test::Unit::AssertionFailedError, "Placeholder not implemented: smtp-expn-response-users-list"
  end

  placeholder "smtp-authenticate-initial-response" do |env, connection, method, credentials, initial_response|
    auth_method = method.downcase.to_s.tr("-", "_").to_sym

    connection.authenticate(credentials[0], credentials[1], auth_method)
  rescue => e
    e
  end

  placeholder "smtp-auth-successful?" do |env, response|
    response.is_a?(Net::SMTP::Response) && response.success?
  end

  placeholder "smtp-auth-credentials-error?" do |env, response|
    response.is_a?(Net::SMTPAuthenticationError) && response.response.status == "535"
  end

  placeholder "smtp-auth-not-supported-error?" do |env, response|
    response.is_a?(Net::SMTPSyntaxError) && response.response.status == "504"
  end
end
