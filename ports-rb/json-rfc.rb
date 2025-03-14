require "json"
require_relative "ports"

suite "suites/json-rfc.ports" do |config|
  config.expected_failures = ["test_n_string_escaped_emoji.json"]

  placeholder "parse" do |_env, json_string|
    JSON.parse(json_string)
  rescue JSON::ParserError => e
    e
  end

  placeholder "list-json-test-files" do |_env|
    Dir.glob("suites/json-rfc-fixtures/*.json").map { |path| File.basename(path) }
  end

  placeholder "parse-success?" do |_env, parse_result|
    !parse_result.is_a?(JSON::ParserError)
  end

  placeholder "file-contents" do |_env, filename|
    File.read(File.join("suites", "json-rfc-fixtures", filename))
  end
end
