require "uri"
require_relative "ports"

test_suite = suite("suites/url-parsing-RFC.ports")

test_suite.placeholder :"url-parse" do |env, url_string|
  URI.parse(url_string)
rescue URI::InvalidURIError => e
  e
end

test_suite.placeholder :"parse-error?" do |env, parse_result|
  parse_result.is_a?(URI::InvalidURIError)
end

test_suite.placeholder :"url-scheme" do |env, uri|
  uri.scheme
end

test_suite.placeholder :"url-authority" do |env, uri|
  authority = uri.host
  authority = "#{uri.userinfo}@#{authority}" if uri.userinfo
  authority = "#{authority}:#{uri.port}" if uri.port
  authority
end

#
# Running
#

test_suite.run
