require "json"
require "test/unit"
require_relative "scheme"

class PortsFunction
  attr_accessor :function, :env

  def initialize(func, env)
    @function = func
    @env = env
  end

  def valid?
    !@function.nil?
  end

  def call(*args)
    @function.call(@env, *args)
  end

  def [](key)
    if key == 0
      ports_role
    elsif key == 1
      self
    end
  end
end

class PortsSetup < PortsFunction
  def ports_role
    :setup
  end
end

class PortsTearDown < PortsFunction
  def ports_role
    :tearDown
  end
end

class Placeholder < PortsFunction
  attr_accessor :name, :parameters, :doc_string

  def initialize(name, parameters, doc_string)
    super(nil, nil)
    @name = name
    @parameters = parameters
    @doc_string = doc_string
  end

  def [](key)
    :placeholder if key == 0
  end

  def template_string
    params = ["env"]
    params += parameters.map { |param| param.to_s.tr("-", "_") }

    <<~TEMPLATE
      placeholder "#{name}" do |#{params.join(", ")}|
        # TODO: Implement
      end
    TEMPLATE
  end
end

def ports_assert(value, msg = "")
  raise Test::Unit::AssertionFailedError, msg || "Expected #{value} to be truthy" unless value
end

def ports_assert_eq(expected, actual)
  raise Test::Unit::AssertionFailedError, "Expected #{actual} to be #{expected}" unless expected == actual
end

class PortsSuite
  attr_reader :scheme_env, :suite_name, :suite_version, :sources,
    :placeholders, :root_capability

  def initialize(file_name)
    @scheme_env = Scheme::Environment.new([], [], Scheme::GLOBAL_ENV)
    initialize_ports_primitives
    initialize_ports
    @suite_source = File.read(file_name)

    @suite_name = nil
    @suite_version = nil
    @sources = nil
    @placeholders = nil
    @root_capability = nil

    @placeholder_functions = {}
    @set_up_functions = []
    @tear_down_functions = []
  end

  def initialize_suite
    @suite_name, @suite_version, @sources,
    @placeholders, @root_capability = eval_scheme(@suite_source)
  end

  def eval_scheme(code, env = nil)
    env ||= @scheme_env
    Scheme.evaluate_string(code, env)
  end

  def eval_scheme_with_args(code, **kwargs)
    env = Scheme::Environment.new([], [], @scheme_env)
    kwargs.each do |key, value|
      env[key.to_sym] = value
    end
    eval_scheme(code, env)
  end

  def create_placeholder(name, parameters, doc_string = "")
    new_placeholder = Placeholder.new(name, parameters, doc_string)
    @scheme_env[name] = new_placeholder
    new_placeholder.env = @scheme_env

    if @placeholder_functions[name]
      new_placeholder.function = @placeholder_functions[name]
    end

    new_placeholder
  end

  def initialize_ports_primitives
    primitives = {
      "create-placeholder" => lambda { |*args| create_placeholder(*args) },
      "is-placeholder?" => lambda { |x| x.is_a?(Placeholder) },
      "assert" => method(:ports_assert),
      "assert-equal" => method(:ports_assert_eq),
      "is-assertion-error?" => lambda { |e| e.is_a?(Test::Unit::AssertionFailedError) }
    }

    primitives.each do |key, value|
      @scheme_env[key.to_sym] = value
    end
  end

  def initialize_ports
    ports_content = File.read("ports/ports.scm")
    eval_scheme(ports_content)
  end

  def placeholder(name, &func)
    @placeholder_functions[name.to_sym] = func
    func
  end

  def set_up(&func)
    @set_up_functions << func
    func
  end

  def tear_down(&func)
    @tear_down_functions << func
    func
  end

  def ensure_placeholders_are_valid
    invalid_placeholders = @placeholders.reject(&:valid?)
    return if invalid_placeholders.empty?

    invalid_placeholder_list = invalid_placeholders.map { |p| "- #{p.name}" }.join("\n")
    placeholders_suggestion = invalid_placeholders.map(&:template_string).join("\n")
    raise [
      "Your test suite is missing definitions for the following placeholders:\n#{invalid_placeholder_list}\n",
      "Implement the missing placeholders:\n#{placeholders_suggestion}"
    ].join("\n")
  end

  def install_set_up_tear_down_functions
    @set_up_functions.each do |func|
      @root_capability[2].unshift(PortsSetup.new(func, @scheme_env))
    end
    @tear_down_functions.each do |func|
      @root_capability[3].unshift(PortsTearDown.new(func, @scheme_env))
    end
  end

  def run(config)
    initialize_suite
    install_set_up_tear_down_functions
    ensure_placeholders_are_valid

    # We set the root-capability in the env, as we need it repeatedly
    @scheme_env[:"root-capability"] = @root_capability

    eval_scheme_with_args(
      "(run-suite suite_name suite_version root-capability only_tests only_capabilities exclude exclude_capabilities expected_failures)",
      suite_name: @suite_name,
      suite_version: @suite_version,
      only_tests: config.only_tests,
      only_capabilities: config.only_capabilities,
      exclude: config.exclude,
      exclude_capabilities: config.exclude_capabilities,
      expected_failures: config.expected_failures || []
    )
  end

  class Config
    attr_accessor :only_tests, :only_capabilities, :exclude, :exclude_capabilities, :expected_failures
  end
end

def suite(file_name, &block)
  config = PortsSuite::Config.new
  obj = PortsSuite.new(file_name)
  obj.instance_exec(config, &block)
  obj.run(config)
end
