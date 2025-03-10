require "json"

module Parser
  def tokenize(expression)
    pattern = /\s*(,@|[('`,)]|"(?:\\.|[^\\"])*"|;.*|[^\s('"`;,)]*)(.*)/
    tokens = []

    expression.split("\n").each do |line|
      part = line
      while (match = part.match(pattern)) && match[0] != ""
        token = match[1]
        if token && token != "" && !token.start_with?(";")
          tokens << token
        end
        part = match[2]
      end
    end
    tokens
  end

  def parse_tokens(tokens)
    return [] if tokens.empty?

    token = tokens.shift
    if token == "("
      list = []
      while tokens[0] != ")"
        list << parse_tokens(tokens)
      end
      tokens.shift # Remove ')'
      list
    elsif token == ")"
      raise "Unexpected ')'"
    elsif token == "'"
      [:quote, parse_tokens(tokens)]
    elsif token == "`"
      [:quasiquote, parse_tokens(tokens)]
    elsif token == ","
      [:unquote, parse_tokens(tokens)]
    elsif token == ",@"
      [:"unquote-splicing", parse_tokens(tokens)]
    else
      parse_atom(token)
    end
  end

  def parse_atom(token)
    lower_token = token.downcase
    if lower_token == "#t" || lower_token == "#true"
      return true
    end
    if lower_token == "#f" || lower_token == "#false"
      return false
    end
    if token[0] == '"'
      raw_string = token[1..-2]
      return raw_string.gsub("\\n", "\n")
          .gsub("\\r", "\r")
          .gsub("\\t", "\t")
    end

    # Try to parse as integer
    begin
      integer = Integer(token)
      return integer
    rescue ArgumentError
      # Not an integer
    end

    # Try to parse as float
    begin
      float = if token.end_with?(".")
        Float("#{token}0")
      else
        Float(token)
      end
      return float
    rescue ArgumentError
      # Not a number
    end

    token.to_sym  # Use Ruby's built-in symbols
  end

  def parse_string(input_string)
    tokens = tokenize(input_string)
    parse_tokens(tokens)
  end

  def matches(structure, target)
    if target.is_a?(Array)
      return false unless structure.is_a?(Array)
      return false unless structure.length == target.length

      result = true
      target.each_with_index do |t, i|
        result &&= matches(structure[i], t)
      end
      result
    elsif target == "Boolean"
      structure == true || structure == false
    elsif target == "String"
      structure.is_a?(String)
    elsif target == "Character"
      structure.is_a?(String) && structure.length == 1
    elsif target == "Symbol"
      structure.is_a?(Symbol)  # Check against Ruby's built-in Symbol class
    elsif target == "Number"
      structure.is_a?(Numeric)
    end
  end

  module_function :parse_string, :tokenize, :parse_tokens, :parse_atom, :matches
end

if __FILE__ == $PROGRAM_NAME
  test_table = JSON.parse(File.read("ports/syntax-tests.json"))

  test_table.each do |entry|
    if entry.is_a?(String)
      puts "\n"
      puts entry
      next
    end

    parse_result = Parser.parse_string(entry[0])
    if Parser.matches(parse_result, entry[1])
      puts "✅: #{entry}"
    else
      puts "❌: #{entry} got #{parse_result.inspect} instead"
    end
  end
  puts "End of test run"
end
