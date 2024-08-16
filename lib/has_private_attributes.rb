# frozen_string_literal: true

require_relative 'has_private_attributes/version'
require 'monitor'

module HasPrivateAttributes
  # @!macro [attach] included
  #   @!extend ClassMethods
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Provides class-level methods for defining private attributes.
  module ClassMethods
    # @!macro [new] private_attribute
    #   @!method $1(*args)
    #   Returns the value of the private attribute '$1'.
    #   @return [Object] The value of the private attribute.
    #   @!visibility private
    #   @note This method is thread-safe.
    #
    #   @!method self.$1(*args)
    #   Returns the class-level value of the private attribute '$1'.
    #   @return [Object] The class-level value of the private attribute.
    #   @!visibility private
    #   @note This method is thread-safe.

    # Defines a private attribute with the given name, value, and optional block.
    #
    # @param name [Symbol] The name of the private attribute.
    # @param value [Object, Proc] The value of the private attribute, or a Proc that will be used to lazily evaluate the value.
    # @yield [*args] An optional block that will be used to lazily evaluate the value of the private attribute.
    # @return [void]
    # @!macro private_attribute
    def private_attribute(name, value = nil, &block)
      ivar_name = "@#{name}"

      define_method(name) do |*args|
        _pa_synchronize do
          if instance_variable_defined?(ivar_name) && args.empty?
            instance_variable_get(ivar_name)
          else
            result = if block_given?
              if block.arity.zero?
                instance_exec(&block)
              else
                HasPrivateAttributes.memoize(self, name) do |*memoized_args|
                  instance_exec(*memoized_args, &block)
                end.call(*args)
              end
            elsif value.respond_to?(:call)
              instance_exec(&value)
            else
              value
            end
            result = HasPrivateAttributes._pa_deep_freeze(result)
            instance_variable_set(ivar_name, result) if args.empty?
            result
          end
        end
      end

      private name

      singleton_class.define_method(name) do |*args|
        @singleton_monitor ||= Monitor.new
        @singleton_monitor.synchronize do
          @singleton_values ||= {}
          return @singleton_values[name] if @singleton_values.key?(name) && args.empty?

          result = if block_given?
            if block.arity.zero?
              class_exec(&block)
            else
              HasPrivateAttributes.memoize(self, name) do |*memoized_args|
                class_exec(*memoized_args, &block)
              end.call(*args)
            end
          elsif value.respond_to?(:call)
            class_exec(&value)
          else
            value
          end

          result = HasPrivateAttributes._pa_deep_freeze(result)
          @singleton_values[name] = result if args.empty?
          result
        end
      end

      private_class_method name
    end
  end

  # @!macro [new] utility_method
  #   @!visibility private

  # Deeply freezes the given object, recursively freezing any nested data structures.
  #
  # @param obj [Object] The object to be deeply frozen.
  # @return [Object] The deeply frozen object.
  # @!macro utility_method
  def self._pa_deep_freeze(obj)
    case obj
    when Hash
      obj.each_with_object({}) { |(k, v), memo| memo[_pa_deep_freeze(k)] = _pa_deep_freeze(v) }.freeze
    when Array
      obj.map { |v| _pa_deep_freeze(v) }.freeze
    when String, Numeric, TrueClass, FalseClass, NilClass
      obj
    else
      obj.clone.freeze
    end
  end

  # Memoizes the result of the given block, keyed by the arguments passed to the block.
  #
  # @param target [Object] The object on which to memoize the result.
  # @param name [Symbol] The name of the memoized value.
  # @yield [*args] The block whose result should be memoized.
  # @return [Proc] A lambda that will return the memoized result.
  # @!macro utility_method
  def self.memoize(target, name)
    target.instance_variable_set("@#{name}_memo", {})
    target.instance_variable_set("@#{name}_memo_mutex", Mutex.new)
    memo = target.instance_variable_get("@#{name}_memo")
    mutex = target.instance_variable_get("@#{name}_memo_mutex")
    lambda do |*args|
      key = args.hash
      mutex.synchronize do
        memo[key] = yield(*args) unless memo.key?(key)
        memo[key]
      end
    end
  end

  # Synchronizes access to instance variables
  #
  # @yield The block to be executed in a synchronized manner
  # @return [Object] The result of the block
  # @!macro utility_method
  def _pa_synchronize(&block)
    @monitor ||= Monitor.new
    @monitor.synchronize(&block)
  end
end
