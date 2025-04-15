require "json"
require_relative "ros"

suite "rosetta-test-suites/json-rfc.ros" do
  expected_failures :test_n_string_escape_x,
    :test_n_string_escaped_emoji,
    :test_n_string_incomplete_surrogate_escape_invalid,
    :test_n_string_invalid_backslash_esc,
    :test_n_string_invalid_utf8_after_escape,
    :test_n_string_unicode_CapitalU,
    :test_n_object_trailing_comment,
    :test_n_structure_object_with_comment

  placeholder "parse" do |_env, json_string|
    JSON.parse(json_string)
  rescue JSON::ParserError => e
    e
  end

  placeholder "list-json-test-files" do |_env|
    Dir.glob("rosetta-test-suites/json-rfc-fixtures/*.json").map { |path| File.basename(path) }
  end

  placeholder "parse-success?" do |_env, parse_result|
    !parse_result.is_a?(JSON::ParserError)
  end

  placeholder "file-contents" do |_env, filename|
    File.read(File.join("rosetta-test-suites", "json-rfc-fixtures", filename))
  end
end
