# frozen_string_literal: true

# JAM Claude Test Framework
# Lightweight TDD framework using only Ruby stdlib — no gems.
#
# Provides:
#   - Assertions module (assert, assert_equal, assert_raises, etc.)
#   - Stubs module (stub_method, with_env, auto-cleanup)
#   - Sandbox module (temp dirs, const redirection, file helpers)
#   - TestCase base class (test discovery, lifecycle, reporting)

require 'tmpdir'
require 'fileutils'
require 'json'

module JamTest
  # ─── Assertions ─────────────────────────────────────────────────────────
  module Assertions
    class AssertionError < StandardError; end

    def assert(value, message = nil)
      return if value

      raise AssertionError, message || "Expected truthy, got #{value.inspect}"
    end

    def assert_equal(expected, actual, message = nil)
      return if expected == actual

      msg = message || "Expected #{expected.inspect}, got #{actual.inspect}"
      raise AssertionError, msg
    end

    def assert_nil(value, message = nil)
      return if value.nil?

      raise AssertionError, message || "Expected nil, got #{value.inspect}"
    end

    def assert_true(value, message = nil)
      return if value == true

      raise AssertionError, message || "Expected true, got #{value.inspect}"
    end

    def assert_false(value, message = nil)
      return if value == false

      raise AssertionError, message || "Expected false, got #{value.inspect}"
    end

    def assert_includes(collection, item, message = nil)
      return if collection.include?(item)

      raise AssertionError, message || "Expected #{collection.inspect} to include #{item.inspect}"
    end

    def assert_match(pattern, string, message = nil)
      pattern = Regexp.new(pattern) if pattern.is_a?(String)
      return if pattern.match?(string)

      raise AssertionError, message || "Expected #{string.inspect} to match #{pattern.inspect}"
    end

    def assert_raises(exception_class, message = nil)
      yield
      raise AssertionError, message || "Expected #{exception_class} to be raised, but nothing was raised"
    rescue exception_class
      true
    end

    def assert_in_range(range, value, message = nil)
      return if range.include?(value)

      raise AssertionError, message || "Expected #{value.inspect} to be in #{range.inspect}"
    end

    def assert_greater_than(expected, actual, message = nil)
      return if actual > expected

      raise AssertionError, message || "Expected #{actual.inspect} > #{expected.inspect}"
    end

    def assert_empty(collection, message = nil)
      return if collection.empty?

      raise AssertionError, message || "Expected empty, got #{collection.inspect}"
    end

    def assert_not_nil(value, message = nil)
      return unless value.nil?

      raise AssertionError, message || 'Expected non-nil value'
    end

    def assert_instance_of(klass, obj, message = nil)
      return if obj.is_a?(klass)

      raise AssertionError, message || "Expected #{klass}, got #{obj.class}"
    end

    def assert_respond_to(obj, method_name, message = nil)
      return if obj.respond_to?(method_name)

      raise AssertionError, message || "Expected #{obj.class} to respond to #{method_name}"
    end
  end

  # ─── Stubs ──────────────────────────────────────────────────────────────
  module Stubs
    class StubRecord
      attr_reader :calls

      def initialize
        @calls = []
      end

      def record_call(args)
        @calls << args
      end

      def called?
        !@calls.empty?
      end

      def call_count
        @calls.size
      end

      def called_with?(*expected_args)
        @calls.any? { |args| args == expected_args }
      end

      def last_args
        @calls.last
      end
    end

    @active_stubs = []

    class << self
      attr_reader :active_stubs

      def reset_all!
        @active_stubs.each do |stub_info|
          target = stub_info[:target]
          method_name = stub_info[:method]
          original = stub_info[:original]

          if stub_info[:singleton]
            target.singleton_class.undef_method(method_name) if target.respond_to?(method_name)
            if original
              target.define_singleton_method(method_name, original)
            end
          else
            target.undef_method(method_name) if target.method_defined?(method_name)
            if original
              target.define_method(method_name, original)
            end
          end
        end
        @active_stubs.clear
      end
    end
  end

  # Stub a method on a target (module/class) and record calls
  # Returns a StubRecord for inspection
  def stub_method(target, method_name, &block)
    record = Stubs::StubRecord.new
    is_singleton = target.is_a?(Module) && !target.is_a?(Class) || target.is_a?(Class)

    # Determine if we're stubbing a singleton method
    if is_singleton && target.respond_to?(method_name)
      original = target.method(method_name)
      Stubs.active_stubs << { target: target, method: method_name, original: original, singleton: true }

      target.define_singleton_method(method_name) do |*args, **kwargs|
        record.record_call(args)
        block ? block.call(*args, **kwargs) : nil
      end
    elsif !is_singleton && target.method_defined?(method_name)
      original = target.instance_method(method_name)
      Stubs.active_stubs << { target: target, method: method_name, original: original, singleton: false }

      target.define_method(method_name) do |*args, **kwargs|
        record.record_call(args)
        block ? block.call(*args, **kwargs) : nil
      end
    else
      # Method doesn't exist yet — define it fresh
      if is_singleton
        Stubs.active_stubs << { target: target, method: method_name, original: nil, singleton: true }
        target.define_singleton_method(method_name) do |*args, **kwargs|
          record.record_call(args)
          block ? block.call(*args, **kwargs) : nil
        end
      end
    end

    record
  end

  # Temporarily override env vars within a block
  def with_env(overrides)
    saved = {}
    overrides.each do |key, value|
      saved[key] = ENV[key]
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
    yield
  ensure
    saved.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  # ─── Sandbox ────────────────────────────────────────────────────────────
  module Sandbox
    @active_const_overrides = []

    class << self
      attr_reader :active_const_overrides

      def reset_all!
        @active_const_overrides.each do |override|
          mod = override[:module]
          const = override[:const]
          original = override[:original]

          mod.send(:remove_const, const) if mod.const_defined?(const, false)
          mod.const_set(const, original) if original
        end
        @active_const_overrides.clear
      end
    end
  end

  # Create a temp directory that auto-cleans on teardown
  def create_sandbox
    @_sandbox_dir = Dir.mktmpdir('jam-test-')
    @_sandbox_dir
  end

  # Redirect a module constant (file path) to sandbox
  # e.g., sandbox_const(ErrorState, :STATE_FILE, 'jam-error-state.json')
  def sandbox_const(mod, const_name, filename)
    raise 'Call create_sandbox first' unless @_sandbox_dir

    original = mod.const_defined?(const_name, false) ? mod.const_get(const_name) : nil
    Sandbox.active_const_overrides << { module: mod, const: const_name, original: original }

    mod.send(:remove_const, const_name) if mod.const_defined?(const_name, false)
    mod.const_set(const_name, File.join(@_sandbox_dir, filename))
  end

  def write_sandbox_file(filename, content)
    raise 'Call create_sandbox first' unless @_sandbox_dir

    path = File.join(@_sandbox_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def read_sandbox_file(filename)
    raise 'Call create_sandbox first' unless @_sandbox_dir

    path = File.join(@_sandbox_dir, filename)
    return nil unless File.exist?(path)

    File.read(path)
  end

  def sandbox_file_exists?(filename)
    raise 'Call create_sandbox first' unless @_sandbox_dir

    File.exist?(File.join(@_sandbox_dir, filename))
  end

  # ─── TestCase ───────────────────────────────────────────────────────────
  class TestCase
    include Assertions
    include Stubs
    include Sandbox
    include JamTest  # with_env, stub_method, sandbox helpers

    # Class-level tracking of all test case subclasses
    @subclasses = []

    class << self
      attr_reader :subclasses

      def inherited(subclass)
        @subclasses ||= []
        @subclasses << subclass
        super
      end

      # Run all test methods in this class
      def run_all
        instance = new
        test_methods = instance.methods.select { |m| m.to_s.start_with?('test_') }.sort
        results = { passed: 0, failed: 0, errors: 0, failures: [] }

        test_methods.each do |method_name|
          instance.setup if instance.respond_to?(:setup)

          begin
            instance.send(method_name)
            print '.'
            results[:passed] += 1
          rescue Assertions::AssertionError => e
            print 'F'
            results[:failed] += 1
            results[:failures] << {
              class: name,
              method: method_name,
              type: :failure,
              message: e.message,
              location: extract_location(e)
            }
          rescue StandardError => e
            print 'E'
            results[:errors] += 1
            results[:failures] << {
              class: name,
              method: method_name,
              type: :error,
              message: "#{e.class}: #{e.message}",
              location: extract_location(e)
            }
          ensure
            begin
              instance.teardown if instance.respond_to?(:teardown)
            rescue StandardError => e
              warn "\n  Teardown error in #{name}##{method_name}: #{e.message}"
            end
          end
        end

        results
      end

      private

      def extract_location(error)
        # Find first backtrace line in test/ directory
        test_line = error.backtrace&.find { |l| l.include?('/test/') }
        test_line || error.backtrace&.first || 'unknown'
      end
    end

    # Default lifecycle methods — override in subclasses
    def setup
      # Reset memoized values on FireColors if loaded
      if defined?(FireColors)
        FireColors.instance_variable_set(:@tier, nil)
        FireColors.instance_variable_set(:@no_color, nil)
      end
    end

    def teardown
      Stubs.reset_all!
      Sandbox.reset_all!
      cleanup_sandbox
    end

    private

    def cleanup_sandbox
      return unless @_sandbox_dir && Dir.exist?(@_sandbox_dir)

      FileUtils.rm_rf(@_sandbox_dir)
      @_sandbox_dir = nil
    end
  end
end
