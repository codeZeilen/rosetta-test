require_relative "parser"

module Scheme
  # Macro table to store defined macros
  MACRO_TABLE = {}

  class Environment
    def initialize(params, args, outer_environment = nil)
      @outer_environment = outer_environment
      if params.is_a?(Symbol)
        @env = {params => args}
      else
        raise "expected #{params.length} arguments, got #{args.length}" unless params.length == args.length
        @env = params.zip(args).to_h
      end
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
    attr_reader :params, :body, :environment

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
    :>= => proc { |a, b| a >= b },
    :< => proc { |a, b| a < b },
    :<= => proc { |a, b| a <= b },
    :"=" => proc { |a, b| a == b },
    :list => proc { |*args| args },
    :cons => proc { |a, b| [a] + b },
    :car => :first.to_proc,
    :cdr => proc { |a| a[1..] },
    :append => proc { |*args| args.flatten(1) },
    :display => proc { |a| print a },
    :inexact => proc { |a| a.to_f },
    :length => :length.to_proc,
    :not => proc { |a| !a },
    :null? => proc { |a| a.nil? || a.empty? },
    :pair? => proc { |x| x.is_a?(Array) && !x.empty? },
    :sqrt => proc { |a| Math.sqrt(a) }
  }.entries.transpose
  GLOBAL_ENV = Environment.new(GLOBAL_DICT[0], GLOBAL_DICT[1])

  # Helper methods for expand
  def is_pair(x)
    x.is_a?(Array) && !x.empty?
  end

  def to_string(x)
    case x
    when true then "#t"
    when false then "#f"
    when Symbol then x.to_s
    when String then "\"#{x.gsub('"', '\"')}\""
    when Array then "(#{x.map { |e| to_string(e) }.join(" ")})"
    else x.to_s
    end
  end

  def require_syntax(x, predicate, msg = "wrong length")
    raise "#{to_string(x)}: #{msg}" unless predicate
  end

  # Main expand function
  def expand(x, toplevel = false)
    # Check for empty list
    require_syntax(x, !(x.is_a?(Array) && x.empty?))

    # Constant/non-list => unchanged
    return x unless x.is_a?(Array)

    case x.first
    when :include
      # (include string1 string2 ...)
      require_syntax(x, x.length > 1)
      expand_include(x)
    when :quote
      # (quote exp)
      require_syntax(x, x.length == 2)
      x
    when :if
      # (if test conseq) => (if test conseq nil)
      if x.length == 3
        x += [nil]
      end
      require_syntax(x, x.length == 4)
      x.map { |xi| expand(xi) }
    when :set
      # (set! var exp)
      require_syntax(x, x.length == 3)
      var = x[1]
      require_syntax(x, var.is_a?(Symbol), "can set! only a symbol")
      [:set!, var, expand(x[2])]
    when :define, :"define-macro"
      # Check correct length
      require_syntax(x, x.length >= 3)

      token, v, body = x[0], x[1], x[2..]

      if v.is_a?(Array) && !v.empty?
        # (define (f args) body) => (define f (lambda (args) body))
        f, *args = v
        expand([token, f, [:lambda, args] + body])
      else
        require_syntax(x, x.length == 3, "wrong length in definition")
        require_syntax(x, v.is_a?(Symbol), "can define only a symbol")
        exp = expand(x[2])

        if token == :"define-macro"
          require_syntax(x, toplevel, "define-macro only allowed at top level")
          proc = evaluate(exp)
          require_syntax(x, proc.respond_to?(:call), "macro must be a procedure")
          MACRO_TABLE[v] = proc
          return nil
        end

        [:define, v, exp]
      end
    when :begin
      # (begin exp*)
      return nil if x.length == 1
      x.map { |xi| expand(xi, toplevel) }
    when :lambda
      # (lambda (vars) exp1 exp2...)
      require_syntax(x, x.length >= 3)

      vars, *body = x[1..]

      # Check that vars is a symbol or list of symbols
      is_valid_vars = vars.is_a?(Symbol) ||
        (vars.is_a?(Array) && vars.all? { |v| v.is_a?(Symbol) })
      require_syntax(x, is_valid_vars, "illegal lambda argument list")

      # Wrap multiple expressions in begin
      exp = (body.length == 1) ? body[0] : [:begin] + body
      [:lambda, vars, expand(exp)]
    when :quasiquote
      # `x => expand_quasiquote(x)
      require_syntax(x, x.length == 2)
      expand_quasiquote(x[1])
    when :cond
      # (cond (test exp) ...)
      expanded_clauses = x[1..].map do |clause|
        require_syntax(x, clause.is_a?(Array) && clause.length == 2,
          "Invalid cond clause format")
        [expand(clause[0]), expand(clause[1])]
      end
      [:cond] + expanded_clauses
    else
      # Check for macro expansion
      if x.first.is_a?(Symbol) && MACRO_TABLE.key?(x.first)
        # (m arg...) => macroexpand if m is a macro
        expand(MACRO_TABLE[x.first].call(*x[1..]), toplevel)
      else
        # (f arg...) => expand each
        x.map { |xi| expand(xi) }
      end
    end
  end

  # Expand quasiquote expression
  def expand_quasiquote(x)
    # 'x => 'x
    unless is_pair(x)
      return [:quote, x]
    end

    # Check for invalid splicing
    require_syntax(x, x[0] != :"unquote-splicing", "can't splice here")

    if x[0] == :unquote
      # ,x => x
      require_syntax(x, x.length == 2)
      x[1]
    elsif is_pair(x[0]) && x[0][0] == :"unquote-splicing"
      # (,@x y) => (append x y)
      require_syntax(x[0], x[0].length == 2)
      [:append, x[0][1], expand_quasiquote(x[1..])]
    else
      # `(x . y) => (cons `x `y)
      [:cons, expand_quasiquote(x[0]), expand_quasiquote(x[1..])]
    end
  end

  # Expand include directive
  def expand_include(x)
    result = [:begin]

    x[1..].each do |file_name|
      File.open(file_name, "r") do |include_file|
        content = include_file.read
        include_result = Parser.parse_string(content)

        if include_result
          result << expand(include_result, true)
        else
          raise SchemeException, "Could not include content of #{file_name}"
        end
      end
    end

    result
  end

  # Let macro implementation
  def let_macro(*args)
    args = [:let] + args.to_a
    require_syntax(args, args.length > 2)

    bindings, *body = args[1..]

    # Validate bindings format
    valid_bindings = bindings.is_a?(Array) &&
      bindings.all? { |b| b.is_a?(Array) && b.length == 2 && b[0].is_a?(Symbol) }
    require_syntax(args, valid_bindings, "illegal binding list")

    # Extract variables and values
    vars = bindings.map { |b| b[0] }
    vals = bindings.map { |b| b[1] }

    # Create lambda expression
    lambda_expr = [[:lambda, vars] + body.map { |b| expand(b) }]

    # Add expanded values
    lambda_expr + vals.map { |v| expand(v) }
  end

  # Register the let macro
  MACRO_TABLE[:let] = proc { |*args| let_macro(*args) }

  # Main evaluation function
  def evaluate(tokens, environment = GLOBAL_ENV)
    loop do
      case tokens
      when Symbol
        return environment.find(tokens)[tokens]
      when Array
        case tokens.first
        when :if
          raise "`if` expected 3 arguments, got #{tokens.length - 1}" unless tokens.length == 4
          condition = evaluate(tokens[1], environment)
          tokens = condition ? tokens[2] : tokens[3]

        when :define
          var = tokens[1]
          expression = tokens[2]
          raise "#{var} is not a symbol" unless var.is_a?(Symbol)

          environment[var] = evaluate(expression, environment)
          return

        when :quote
          raise "`quote` expected 1 argument, got #{tokens.length - 1}" unless tokens.length == 2
          return tokens[1]

        when :lambda
          raise "`lambda` expected 2 argument, got #{tokens.length - 1}" unless tokens.length == 3
          raise "invalid argument list (expected symbol or list of symbols)" if !tokens[1].is_a?(Symbol) && !(tokens[1].is_a?(Array) && tokens[1].all? { |t| t.is_a?(Symbol) })
          return Procedure.new(tokens[1], tokens[2], environment)

        when :begin
          tokens[1...-1].each { |t| evaluate(t, environment) }
          tokens = tokens[-1]

        when :set!
          raise "`set!` expected 2 argument, got #{tokens.length - 1}" unless tokens.length == 3

          var = tokens[1]
          expression = tokens[2]
          environment.find(var)[var] = evaluate(expression, environment)
          return

        when :cond
          branch = tokens[1..].find do |(test, expression)|
            test == :else || evaluate(test, environment)
          end
          return if branch.nil?

          tokens = branch[1]

        else
          expressions = tokens.map { |t| evaluate(t, environment) }
          procedure = expressions.shift
          if procedure.is_a?(Procedure)
            tokens = procedure.body
            environment = Environment.new(procedure.params, expressions, procedure.environment)
          elsif procedure.nil?
            raise "Undefined procedure: #{tokens.first}"
          else
            return procedure.call(*expressions)
          end
        end
      else
        return tokens
      end
    end
  end

  def evaluate_string(source)
    Scheme.evaluate(Scheme.expand(Parser.parse_string(source), true))
  end

  module_function :evaluate_string, :evaluate, :expand, :is_pair, :require_syntax,
    :expand_quasiquote, :expand_include, :let_macro, :to_string

  # Get current directory
  dirname = File.dirname(__FILE__)

  begin
    stdlib = File.join(dirname, "../ports/stdlib.scm")
    evaluate_string(File.read(stdlib))
  rescue => error
    puts "Error loading standard library: #{error.message}"
    exit(1)
  end
end
