require_relative "parser"

module Scheme
  class Environment
    def initialize(params, args, outer_environment = nil)
      @outer_environment = outer_environment

      @env = params.zip(args).to_h
    end

    def [](key)
      @env[key]
    end

    def []=(key, value)
      @env[key] = value
    end

    def find(key)
      if @env.key?(key)
        self
      elsif !@outer_environment.nil?
        @outer_environment.find(key)
      else
        raise "Lookup error for #{key}"
      end
    end
  end

  class Procedure
    def initialize(params, body, environment)
      @params = params
      @body = body
      @environment = environment
    end

    def call(*args)
      Scheme.evaluate(@body, Environment.new(@params, args, @environment))
    end
  end

  GLOBAL_DICT = {
    :+ => proc { |a, b| a + b },
    :* => proc { |a, b| a * b },
    :- => proc { |a, b| a - b },
    :/ => proc { |a, b| a / b },
    :> => proc { |a, b| a > b },
    :< => proc { |a, b| a < b }
  }.entries.transpose
  GLOBAL_ENV = Environment.new(GLOBAL_DICT[0], GLOBAL_DICT[1])

  def evaluate(tokens, environment = GLOBAL_ENV)
    if tokens.is_a?(String)
      tokens
    elsif tokens.is_a?(Numeric)
      tokens
    elsif tokens.is_a?(Array)
      case tokens.first
      when :if
        condition = evaluate(tokens[1], environment)
        branch = condition ? tokens[2] : tokens[3]
        evaluate(branch, environment)
      when :define
        environment[tokens[1]] = evaluate(tokens[2], environment)
        nil
      when :quote
        tokens[1]
      when :lambda
        Procedure.new(tokens[1], tokens[2], environment)
      else
        token = tokens.first
        procedure = evaluate(token, environment)
        procedure.call(
          *(tokens[1..].map { |t| evaluate(t, environment) })
        )
      end
    elsif tokens.is_a?(Symbol)
      environment.find(tokens)[tokens]
    end
  end

  def evaluate_string(source)
    Scheme.evaluate(Parser.parse_string(source))
  end

  module_function :evaluate_string, :evaluate
end
