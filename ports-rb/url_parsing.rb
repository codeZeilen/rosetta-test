require "uri"
require_relative "ports"

suite "suites/url-parsing-RFC.ports" do
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
