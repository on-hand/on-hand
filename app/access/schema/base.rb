# frozen_string_literal: true

module Schema
  class Base
    attr_accessor :fields, :drys
    delegate :[], :fetch, to: :fields

    def self.define(drys:, &block)
      data = new
      data.fields = { }.with_indifferent_access
      data.drys = drys
      returned = data.instance_eval(&block)
      return data unless returned.is_a?(Hash) || returned.is_a?(Array)

      data
    end

    def use(name, api: nil)
      #
    end

    # @!method string(param_name, **opt)
    # @!method string!(param_name, **opt)
    Type::ALL.each do |type|
      define_method(type) do |param_name, **opt, &block|
        fields[param_name] = Field.define(type, param_name, **opt, &block)
      end
      define_method("#{type}!") do |param_name, **opt, &block|
        fields[param_name] = Field.define(type, param_name, required: true, **opt, &block)
      end
    end

    # @param [Hash] values
    def cast(values)
      values.map do |key, value|
        next { } if (field = fields[key]).nil?

        { (field.to_name || key) => field.cast(value) }
      end.reduce(:merge).compact
    end
  end
end
