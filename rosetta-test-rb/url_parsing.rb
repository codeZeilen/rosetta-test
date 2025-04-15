require "uri"
require_relative "rosetta"

suite "rosetta-test-suites/url-parsing-rfc.ros" do
  expected_failures :test_scheme_with_invalid_characters,
    :"test_non-terminated_scheme",
    :test_invalid_ipv4_host

  placeholder "url-parse" do |_env, url_string|
    URI.parse(url_string)
  rescue URI::InvalidURIError => e
    e
  end

  placeholder "parse-error?" do |_env, parse_result|
    parse_result.is_a?(URI::InvalidURIError)
  end

  placeholder "url-scheme" do |_env, uri|
    uri.scheme
  end

  placeholder "url-authority" do |_env, uri|
    authority = uri.host
    authority = "#{uri.userinfo}@#{authority}" if uri.userinfo
    authority = "#{authority}:#{uri.port}" if uri.port
    authority
  end
end
