# frozen_string_literal: true

module Schema
  class Field < Struct.new(
    :type, :scope, :name, :map_name, :default, :validators, :nested_fields
  )
    def self.define(
      type:, name:, scope:, default: nil, array: false, to: nil, **validators, &block
    )
      new(
        type: FieldType.new(type:, array:),
        map_name: to, name:, scope:, default:, validators:
      ).tap do |it|
        it.scoping(&block) if it.type.json? && block_given?
      end
    end

    def cast(value)
      casted = type.cast(value, default:)
      if validators.present?
        failed = type.validate(casted, **validators)
        invalid!(failed) if failed.present?
      end

      if nested_fields.present?
        if type.array?
          casted&.map { nested_fields.cast(_1) }
        else
          nested_fields.cast(casted)
        end
      else
        casted
      end
    end

    def cast_with_name(value)
      { (map_name || name) => cast(value) }
    end

    def dup_with(**options)
      dup.tap do |it|
        it.default = options.delete(:default) if options.key?(:default)
        it.map_name = options.delete(:to) if options.key?(:to)
        if options.key?(:scope)
          it.scope = options.delete(:scope).(it.name)
          it.scoping { it.nested_fields } if it.nested_fields.present?
        end
        it.validators.merge!(options)
      end
    end

    def scoping(&block)
      self.nested_fields = scope.define(&block)
    end

    private

    class Error < StandardError; end

    # TODO: move to fields
    # TODO: `notes[].title`
    def invalid!(msg)
      raise Error, "#{scope.fields_type} `#{scope.path.join(".")}` is invalid: should #{msg}"
    end
  end
end
