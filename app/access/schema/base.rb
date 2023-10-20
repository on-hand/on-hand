# frozen_string_literal: true

module Schema
  class Base
    attr_accessor :fields, :drys
    delegate :[], :fetch, to: :fields

    def self.define(drys: { }, &block)
      schema   = new
      returned = schema.tap do |it|
        it.fields = { }.with_indifferent_access
        it.drys = drys

        case it.class.name
        when /Params/   then it.use(:params)
        when /Headers/  then it.use(:headers)
        when /Response/ then it.use(:response)
        end if drys.present?

        it.instance_eval(&block)
      end
      schema.drys = nil
      return schema unless returned.is_a?(Hash) || returned.is_a?(Array)

      schema
    end

    def use(*names, api: nil)
      names.each { merge(drys.fetch(_1)) }
    end

    def use!(*names)
      #
    end

    # @!method string(param_name, **opt)
    # @!method string!(param_name, **opt)
    Type::ALL.each do |type|
      define_method(type) do |param_name, **opt, &block|
        opt.merge!(scope: self.class.name)
        fields[param_name] = Field.define(type, param_name, **opt, &block)
      end
      define_method("#{type}!") do |param_name, **opt, &block|
        opt.merge!(scope: self.class.name)
        fields[param_name] = Field.define(type, param_name, required: true, **opt, &block)
      end
    end

    # @param [Hash] values
    def cast(values)
      fields.map do |name, field|
        field.cast_with_map(values[name] || values[name.to_sym])
      end.reduce(:merge).compact
    end

    private

    def merge(schema)
      fields.merge!(
        schema.is_a?(Hash) ? schema : schema.fields
      )
    end
  end
end
