require_relative "parser"

module Scheme
  GLOBAL_ENV = {
    :+ => proc { |a, b| a + b },
    :* => proc { |a, b| a * b }
  }

  def evaluate(tokens)
    if tokens.is_a?(String)
      tokens
    elsif tokens.is_a?(Numeric)
      tokens
    elsif tokens.is_a?(Array)
      token = tokens.shift
      procedure = evaluate(token)
      procedure.call(
        *(tokens.map { |t| evaluate(t) })
      )
    elsif tokens.is_a?(Symbol)
      GLOBAL_ENV[tokens]
    end
  end

  def evaluate_string(source)
    Scheme.evaluate(Parser.parse_string(source))
  end

  module_function :evaluate_string, :evaluate
end
