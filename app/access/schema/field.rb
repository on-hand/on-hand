# frozen_string_literal: true

module Schema
  class Field < Struct.new(
    :type, :scope, :name, :map_name, :default, :validators
  )
    def self.define(
      type, name, default: nil, array: false, to: nil, **validators, &block
    )
      new(
        type: FieldType.new(type:, array:),
        map_name: to, name:, default:, validators:
      )
    end

    def cast(value)
      type.cast(value, default:).tap do |it|
        if validators.present?
          failed = type.validate(it, **validators)
          invalid!(failed) if failed.present?
        end
      end
    end

    def cast_with_map(value)
      { (map_name || name) => cast(value) }
    end

    def dup_with(**options)
      deep_dup.tap do |it|
        it.default = options.delete(:default) if options.key?(:default)
        it.map_name = options.delete(:to) if options.key?(:to)
        it.scope = options.delete(:scope) if options.key?(:scope)
        it.validators.merge!(options)
      end
    end

    private

    class Error < StandardError; end
    def invalid!(msg) = raise Error, "#{scope.schema_type} `#{name}` is invalid: should #{msg}"
  end
end
