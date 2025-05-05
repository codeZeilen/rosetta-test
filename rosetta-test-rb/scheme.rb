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

  EOF_OBJECT = :"#<eof-object>"

  GLOBAL_DICT = {
    :+ => proc { |a, b| a + b },
    :* => proc { |a, b| a * b },
    :- => proc { |a, b| a - b },
    :/ => proc { |a, b| a / b },
    :modulo => proc { |a, b| a % b },
    :> => proc { |a, b| a > b },
    :>= => proc { |a, b| a >= b },
    :< => proc { |a, b| a < b },
    :<= => proc { |a, b| a <= b },
    :"=" => proc { |a, b| a == b },
    :abs => proc { |a| a.abs },
    :append => proc { |*args| args.flatten(1) },
    :apply => proc { |procedure, list| procedure.call(*list) },
    :boolean? => proc { |a| [true, false].include?(a) },
    :car => proc { |a| a[0] },
    :cdr => proc { |a| a[1..] },
    :cons => proc { |a, b| [a] + b },
    :display => proc { |a| print a },
    :eq? => proc { |a, b| a == b },
    :eqv? => proc { |a, b| a == b },
    :equal? => proc { |a, b| a == b },
    :error => proc { |msg| StandardError.new(msg) },
    :exit => proc { |a| Kernel.exit(a) },
    :inexact => proc { |a| a.to_f },
    :length => :length.to_proc,
    :list? => proc { |a| a.is_a?(Array) },
    :list => proc { |*args| args },
    :"list-ref" => proc { |list, idx| list[idx] },
    :"list-set!" => proc { |list, idx, value| list[idx] = value },
    :"make-hash-table" => proc { Hash.new },
    :"hash-table?" => proc { |a| a.is_a?(Hash) },
    :"hash-table-ref-prim" => proc { |hash, key| hash[key] },
    :"hash-table-set!" => proc { |*args| (args[0][args[1]] = args[2]) ? nil : nil },
    :"hash-table-delete!" => proc { |*args| args[0].delete(args[1]) ? nil : nil },
    :"hash-table-keys" => proc { |a| a.keys },
    :"hash-table-values" => proc { |a| a.values },
    :not => proc { |a| !a },
    :null? => proc { |a| a.nil? || (a.respond_to?(:empty?) && a.empty?) },
    :pair? => proc { |tokens| tokens.is_a?(Array) && !tokens.empty? },
    :raise => proc { |e| raise e },
    :sqrt => proc { |a| Math.sqrt(a) },
    :"string-append" => proc { |*strings| strings.join("") },
    :"string-downcase" => proc { |s| s.downcase },
    :"string-index" => proc { |s, sub| s.index(sub) || false },
    :"string-replace" => proc { |old, new, s| s.gsub(old, new) },
    :"string-split" => proc { |s, sep| s.split(sep) },
    :"string-trim" => proc { |s| s.strip },
    :"string-upcase" => proc { |s| s.upcase },
    :"eof-object?" => proc { |a| a == EOF_OBJECT },
    :symbol? => proc { |a| a.is_a?(Symbol) },
    :"with-exception-handler" => proc { |handler, body|
      begin
        body.call
      rescue => e
        handler.call(e)
      end
    },
    :"open-output-file" => proc { |filename| [File.open(filename, "w"), "w"] },
    :"open-input-file" => proc { |filename| [File.open(filename, "r"), "r"] },
    :"close-port" => proc { |port_tuple | port_tuple[0].close },
    :"port?" => proc { |port_tuple| port_tuple[0].is_a?(File) },
    :"output-port?" => proc { |port_tuple| port_tuple[0].is_a?(File) && port_tuple[1] == "w" },
    :"input-port?" => proc { |port_tuple| port_tuple[0].is_a?(File) && port_tuple[1] == "r" },
    :"read-char" => proc { |port_tuple| 
      begin
        port_tuple[0].readchar
      rescue EOFError
        EOF_OBJECT
      end},
    :"write-char" => proc { |char, port_tuple| port_tuple[0].write(char) }

  }.entries.transpose
  GLOBAL_ENV = Environment.new(GLOBAL_DICT[0], GLOBAL_DICT[1])

  # Helper methods for expand
  def pair?(tokens)
    tokens.is_a?(Array) && !tokens.empty?
  end

  def to_string(tokens)
    case tokens
    when true then "#t"
    when false then "#f"
    when Symbol then tokens.to_s
    when String then "\"#{tokens.gsub('"', '\"')}\""
    when Array then "(#{tokens.map { |e| to_string(e) }.join(" ")})"
    else tokens.to_s
    end
  end

  def require_syntax(tokens, predicate, msg = "wrong length")
    raise "#{to_string(tokens)}: #{msg}" unless predicate
  end

  # Main expand function
  def expand(tokens, toplevel: false)
    # Check for empty list
    require_syntax(tokens, !(tokens.is_a?(Array) && tokens.empty?))

    # Constant/non-list => unchanged
    return tokens unless tokens.is_a?(Array)

    case tokens.first
    when :include
      # (include string1 string2 ...)
      require_syntax(tokens, tokens.length > 1)
      expand_include(tokens)
    when :quote
      # (quote exp)
      require_syntax(tokens, tokens.length == 2)
      tokens
    when :if
      # (if test conseq) => (if test conseq nil)
      tokens += [nil] if tokens.length == 3
      require_syntax(tokens, tokens.length == 4)
      tokens.map { |token| expand(token) }
    when :set
      # (set! var exp)
      require_syntax(tokens, tokens.length == 3)
      var = tokens[1]
      require_syntax(tokens, var.is_a?(Symbol), "can set! only a symbol")
      [:set!, var, expand(tokens[2])]
    when :define, :"define-macro"
      # Check correct length
      require_syntax(tokens, tokens.length >= 3)

      token, v, body = tokens[0], tokens[1], tokens[2..]

      if v.is_a?(Array) && !v.empty?
        # (define (f args) body) => (define f (lambda (args) body))
        f, *args = v
        expand([token, f, [:lambda, args] + body])
      else
        require_syntax(tokens, tokens.length == 3, "wrong length in definition")
        require_syntax(tokens, v.is_a?(Symbol), "can define only a symbol")
        exp = expand(tokens[2])

        if token == :"define-macro"
          require_syntax(tokens, toplevel, "define-macro only allowed at top level")
          proc = evaluate(exp)
          require_syntax(tokens, proc.respond_to?(:call), "macro must be a procedure")
          MACRO_TABLE[v] = proc
          return nil
        end

        [:define, v, exp]
      end
    when :begin
      # (begin exp*)
      return nil if tokens.length == 1

      tokens.map { |token| expand(token, toplevel: toplevel) }
    when :lambda
      # (lambda (vars) exp1 exp2...)
      require_syntax(tokens, tokens.length >= 3)

      vars, *body = tokens[1..]

      # Check that vars is a symbol or list of symbols
      is_valid_vars = vars.is_a?(Symbol) ||
        (vars.is_a?(Array) && vars.all? { |v| v.is_a?(Symbol) })
      require_syntax(tokens, is_valid_vars, "illegal lambda argument list")

      # Wrap multiple expressions in begin
      exp = (body.length == 1) ? body[0] : [:begin] + body
      [:lambda, vars, expand(exp)]
    when :quasiquote
      # `x => expand_quasiquote(x)
      require_syntax(tokens, tokens.length == 2)
      expand_quasiquote(tokens[1])
    when :cond
      # (cond (test exp) ...)
      expanded_clauses = tokens[1..].map do |clause|
        require_syntax(tokens, clause.is_a?(Array) && clause.length == 2,
          "Invalid cond clause format")
        [expand(clause[0]), expand(clause[1])]
      end
      [:cond] + expanded_clauses
    else
      # Check for macro expansion
      if tokens.first.is_a?(Symbol) && MACRO_TABLE.key?(tokens.first)
        # (m arg...) => macroexpand if m is a macro
        expand(MACRO_TABLE[tokens.first].call(*tokens[1..]), toplevel: toplevel)
      else
        # (f arg...) => expand each
        tokens.map { |token| expand(token) }
      end
    end
  end

  # Expand quasiquote expression
  def expand_quasiquote(tokens)
    # 'x => 'x
    return [:quote, tokens] unless pair?(tokens)

    # Check for invalid splicing
    require_syntax(tokens, tokens[0] != :"unquote-splicing", "can't splice here")

    if tokens[0] == :unquote
      # ,x => x
      require_syntax(tokens, tokens.length == 2)
      tokens[1]
    elsif pair?(tokens[0]) && tokens[0][0] == :"unquote-splicing"
      # (,@x y) => (append x y)
      require_syntax(tokens[0], tokens[0].length == 2)
      [:append, tokens[0][1], expand_quasiquote(tokens[1..])]
    else
      # `(x . y) => (cons `x `y)
      [:cons, expand_quasiquote(tokens[0]), expand_quasiquote(tokens[1..])]
    end
  end

  # Expand include directive
  def expand_include(tokens)
    result = [:begin]

    tokens[1..].each do |file_name|
      File.open(file_name, "r") do |include_file|
        content = include_file.read
        include_result = Parser.parse_string(content)
        raise "Could not include content of #{file_name}" unless include_result

        result << expand(include_result, toplevel: true)
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
          if !tokens[1].is_a?(Symbol) && !(tokens[1].is_a?(Array) && tokens[1].all? { |t| t.is_a?(Symbol) })
            raise "invalid argument list (expected symbol or list of symbols)"
          end

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
          branch = tokens[1..].find do |(test, _)|
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

  def evaluate_string(source, env = GLOBAL_ENV)
    Scheme.evaluate(Scheme.expand(Parser.parse_string(source), toplevel: true), env)
  end

  module_function :evaluate_string, :evaluate, :expand, :pair?, :require_syntax,
    :expand_quasiquote, :expand_include, :let_macro, :to_string

  # Get current directory
  dirname = File.dirname(__FILE__)

  begin
    stdlib = File.join(dirname, "../rosetta-test/stdlib.scm")
    evaluate_string(File.read(stdlib))
  rescue => e
    puts e.backtrace
    puts "Error loading standard library: #{e.message}"
    exit(1)
  end
end
