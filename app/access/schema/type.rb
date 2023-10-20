# frozen_string_literal: true

module Schema
  class Type
    attr_accessor :type, :array

    ALL = %i[
      string integer float boolean
      date time
      json
    ].freeze
    Decimal = ActiveModel::Type::Decimal.new
    TrueValues = [ 1, true, *%w[ 1 yes true T YES 是 √ ] ].freeze
    ArraySplitter = /, |,| |\n/

    def initialize(type, array: false)
      self.type  = type
      self.array = array
    end

    def cast(value, array = array?)
      return if value.blank?

      if type == :json
        value.is_a?(String) ? Oj.load(value) : value
      elsif array
        value.is_a?(String) ? value.split(ArraySplitter).map { cast(_1, false) } : Array(value)
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
    end

    def array? = array
  end
end
