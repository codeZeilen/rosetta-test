require "json"
require "pathname"

# Helper function to check if result matches expected output
def matches(result, target)
  if target.is_a?(Hash) && target.key?("type")
    return result.is_a?(StandardError)
  end

  if target.is_a?(Array)
    return false unless result.is_a?(Array)
    return false unless result.length == target.length

    match = true
    target.each_with_index do |t, i|
      match &&= matches(result[i], t)
    end
    return match
  end

  if result.is_a?(Symbol)
    return result.to_s == target
  end

  result == target
end

# Get current directory
dirname = File.dirname(__FILE__)

# Load test cases
test_table = []
begin
  tests_path1 = File.join(dirname, "../ports/lispy-tests.json")
  tests_path2 = File.join(dirname, "../ports/lispy-tests2.json")

  tests1 = JSON.parse(File.read(tests_path1))
  test_table.concat(tests1)

  tests2 = JSON.parse(File.read(tests_path2))
  test_table.concat(tests2)
rescue => error
  puts "Error loading test files: #{error.message}"
  exit(1)
end

# Import the scheme module - assuming it's defined in a Ruby file
require_relative "scheme"

# Run tests

total = test_table.length
failed = 0

test_table.each do |entry|
  input = entry["input"]

  begin
    eval_result = Scheme.evaluate_string(input)
  rescue => error
    eval_result = error
  end

  if matches(eval_result, entry["expected"])
    puts "✅: #{input}"
  else
    puts "❌: #{input} got #{eval_result}[#{eval_result.class}] instead of #{entry["expected"]}[#{entry["expected"].class}]"
    failed += 1
  end
end
puts "#{total} tests run, #{failed} failed"
