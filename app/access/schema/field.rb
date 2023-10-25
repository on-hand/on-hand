# frozen_string_literal: true

module Schema
  class Field < Struct.new(
    :type, :scope, :name, :as, :default, :validators, :nested_fields
  )
    def self.define(
      type:, name:, scope:, persistence:,
      default: nil, array: false, save_as: nil, as: save_as,
      **validators, &block
    )
      name, array = name.first, true if name.is_a?(Array)
      scope.path[-1] = { name:, array:, as: }
      persistence.uid_path = scope.path_aliases if (as || name).to_sym == :uid

      new(
        type: FieldType.new(type:, array:),
        as:, name:, scope:, default:, validators:
      ).tap do |it|
        it.scoping(persistence:, &block) if it.type.json? && block_given?
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
      { (as || name) => cast(value) }
    end

    # TODO: refactor
    def dup_with(**options)
      dup.tap do |it|
        persistence = options.delete(:persistence)
        it.default = options.delete(:default) if options.key?(:default)
        it.as = options.delete(:as) if options.key?(:as)
        if options.key?(:scope)
          it.scope = options.delete(:scope).(name: it.name)
          it.scoping(persistence:) { it.nested_fields } if it.nested_fields.present?
        end
        it.validators.merge!(options)
      end
    end

    def scoping(**, &block)
      self.nested_fields = scope.define(**, &block)
    end

    private

    class Error < StandardError; end

    # TODO: move to fields
    def invalid!(msg)
      raise Error, "#{scope.fields_type} `#{scope.path_inspect}` is invalid: should #{msg}"
    end
  end
end
