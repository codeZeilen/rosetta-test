require "json"
require "test/unit"
require_relative "scheme"

class RosettaFunction
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
      rosetta_role
    elsif key == 1
      self
    end
  end
end

class RosettaSetup < RosettaFunction
  def rosetta_role
    :setup
  end
end

class RosettaTearDown < RosettaFunction
  def rosetta_role
    :tearDown
  end
end

class Placeholder < RosettaFunction
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
        raise Test::Unit::AssertionFailedError, "Placeholder not implemented: #{@name}"
      end
    TEMPLATE
  end
end

def rosetta_assert(value, msg = "")
  raise Test::Unit::AssertionFailedError, msg || "Expected #{value} to be truthy" unless value
end

def rosetta_assert_eq(expected, actual)
  raise Test::Unit::AssertionFailedError, "Expected #{actual} to be #{expected}" unless expected == actual
end

def rosetta_thread(proc)
  Thread.new { proc.call }
end

def rosetta_thread_kill(thread)
  Thread.kill(thread)
end

def rosetta_thread_join(thread)
  # thread.join
  Thread.kill(thread)
end

def rosetta_thread_sleep(time)
  sleep(time)
end

def rosetta_thread_yield
  # Thread.pass
  sleep(0)
end

class RosettaTestSuite
  attr_reader :scheme_env, :suite_name, :bridge_name, :suite_version, 
    :sources, :placeholders, :root_capability

  def initialize(bridge_name, file_name)
    @scheme_env = Scheme::Environment.new([], [], Scheme::GLOBAL_ENV)
    initialize_rosetta_primitives
    initialize_rosetta
    @suite_source = File.read(file_name)
    @bridge_name = bridge_name

    @suite = nil

    @placeholder_functions = {}
    @set_up_functions = []
    @tear_down_functions = []

    @config = Config.new
  end

  def initialize_suite
    @suite = eval_scheme(@suite_source)
    suite_eval("(suite-set-bridge-name! the_suite bridge_name)", :bridge_name => @bridge_name)
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

  def suite_eval(code, **kwargs)
    eval_scheme_with_args(code, :the_suite=>@suite, **kwargs)
  end

  def suite_placeholders()
    suite_eval("(suite-placeholders the_suite)")
  end

  def suite_root_capability()
    suite_eval("(suite-root-capability the_suite)")
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

  def initialize_rosetta_primitives
    primitives = {
      "create-placeholder" => lambda { |*args| create_placeholder(*args) },
      "is-placeholder?" => lambda { |x| x.is_a?(Placeholder) },
      "assert" => method(:rosetta_assert),
      "assert-equal" => method(:rosetta_assert_eq),
      "is-assertion-error?" => lambda { |e| e.is_a?(Test::Unit::AssertionFailedError) },
      "thread" => method(:rosetta_thread),
      "thread-wait-for-completion" => method(:rosetta_thread_join),
      "thread-sleep!" => method(:rosetta_thread_sleep),
      "thread-yield" => method(:rosetta_thread_yield),
      "rosetta-test-host" => lambda { "ruby" }
    }

    primitives.each do |key, value|
      @scheme_env[key.to_sym] = value
    end
  end

  def initialize_rosetta
    rosetta_content = File.read("rosetta-test/rosetta-test.scm")
    eval_scheme(rosetta_content)
  end

  def placeholder(name, &func)
    puts "WARNING: Placeholder #{name} is defined multiple times" if @placeholder_functions.key?(name.to_sym)
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
    invalid_placeholders = suite_placeholders.reject(&:valid?)
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
      suite_root_capability[2].unshift(RosettaSetup.new(func, @scheme_env))
    end
    @tear_down_functions.each do |func|
      suite_root_capability[3].unshift(RosettaTearDown.new(func, @scheme_env))
    end
  end

  def run
    initialize_suite
    install_set_up_tear_down_functions
    ensure_placeholders_are_valid

    suite_eval("(suite-set-only-tests! the_suite only_tests)", :only_tests => @config.only_tests)
    suite_eval("(suite-set-only-capabilities! the_suite only_capabilities)", :only_capabilities => @config.only_capabilities)
    suite_eval("(suite-set-exclude-tests! the_suite exclude)", :exclude => @config.exclude)
    suite_eval("(suite-set-exclude-capabilities! the_suite exclude_capabilities)", :exclude_capabilities => @config.exclude_capabilities)
    suite_eval("(suite-set-expected-failures! the_suite expected_failures)", :expected_failures => @config.expected_failures)
    suite_eval("(suite-run the_suite argv)", :argv => ARGV)
  end

  CONFIG_FIELDS = [:only_tests, :only_capabilities, :exclude, :exclude_capabilities, :expected_failures]

  # Define a setter for each config field
  CONFIG_FIELDS.each do |field|
    define_method field do |*names|
      @config.public_send(:"#{field}=", names.map(&:to_s))
    end
  end

  class Config
    attr_accessor(*CONFIG_FIELDS)

    def initialize
      @expected_failures = []
    end

    def to_h
      CONFIG_FIELDS.map do |key|
        [key, public_send(key)]
      end.to_h
    end
  end
end

def suite(bridge_name, file_name, &block)
  obj = RosettaTestSuite.new(bridge_name, file_name)
  obj.instance_eval(&block)
  obj.run
end

def fixture_path(file_name)
  File.join(".", "suites", file_name)
end
