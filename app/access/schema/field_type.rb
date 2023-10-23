# frozen_string_literal: true

module Schema
  class FieldType < Struct.new(
    :type, :array
  )
    ALL = %i[
      string integer float boolean
      date time file
      json
    ].freeze
    Decimal = ActiveModel::Type::Decimal.new
    TrueValues = [ 1, true, *%w[ 1 yes true T YES 是 √ ] ].freeze
    ArraySplitter = /, |,| |\n/

    def cast(value, array: array?, default: nil)
      return default if value.blank?

      if type == :json
        value.is_a?(String) ? Oj.load(value) : value
      elsif array
        value.is_a?(String) ? value.split(ArraySplitter).map { cast(_1, array: false) } : Array(value)
      else
        case type
        when :string  then value.to_s
        when :integer then value.to_i
        when :float   then Decimal.cast(value)
        when :date    then value.to_date
        when :time    then value.to_time
        when :boolean then value.in?(TrueValues) ? true : false
        else value
        end
      end
    rescue => e
      raise Error, "Cast `#{value}` to `#{type}` failed: #{e.message}"
    end

    def validate(casted, **validators)
      validators.each do |name, spec|
        case name
        when :required
          validators.delete(name) if !spec || casted.present?
        # TODO
        end
      end
    end

    def array? = array
    ALL.each do |type_name|
      define_method("#{type_name}?") { type == type_name }
    end

    class Error < StandardError; end
  end
end
