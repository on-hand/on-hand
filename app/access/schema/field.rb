# frozen_string_literal: true

module Schema
  class Field
    attr_accessor :type, :scope, :name, :map_name
    attr_accessor :required, :default, :validators

    def self.define(
      type, name, scope:,
      required: false,
      default: nil,
      array: false,
      to: nil,
      **validators,
      &block
    )
      new.tap do |it|
        it.name  = name
        it.type  = Type.new(type, array:)
        it.scope = scope.split("::").last.singularize
        it.map_name = to
        it.required = required
        it.default  = default
        it.validators = validators

        if it.scope == "Header"
          it.map_name ||= name.to_s.underscore.split("_").map(&:capitalize).join("-")
        end
      end
    end

    def cast(value)
      type.cast(value, default:).tap do |it|
        required! if required && it.nil?
        failed = type.validate(it, **validators)
        invalid!(failed) if failed.present?
      end
    end

    def cast_with_map(value)
      { (map_name || name) => cast(value) }
    end

    private

    class Error < StandardError; end
    def required! = raise Error, "#{scope} `#{name}` is required"
    def invalid!(msg) = raise Error, "#{scope} `#{name}` is invalid: should #{msg}"
  end
end
