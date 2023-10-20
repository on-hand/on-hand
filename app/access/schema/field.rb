# frozen_string_literal: true

module Schema
  class Field
    attr_accessor :type, :name, :to_name

    def self.define(
      type, name,
      required: false,
      array: false,
      to: nil,
      &block
    )
      field      = new
      field.name = name
      field.type = Type.new(type, array:)
      field.to_name = to
      field
    end

    def cast(value)
      type.cast(value)
    end
  end
end
