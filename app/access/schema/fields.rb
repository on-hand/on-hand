# frozen_string_literal: true

module Schema
  class Fields
    attr_accessor :list, :scope
    delegate :[], :[]=, :fetch, :map, :each, :merge!, to: :list

    def self.define(scope:, &block)
      schema   = new
      returned = schema.tap do |it|
        it.list = { }.with_indifferent_access
        it.scope = scope

        # auto-use default dry block
        case it.class.name
        when /Params/   then it.use(:params)
        when /Headers/  then it.use(:headers)
        when /Response/ then it.use(:response)
        end unless scope.inside_dry?

        it.instance_eval(&block)
      end
      return schema unless returned.is_a?(Hash) || returned.is_a?(Array)

      schema
    end

    def use(*names, **options)
      names.each { merge(scope.drys.fetch(_1), scope: scoping, **options) }
    end

    def use!(*names)
      use(*names, required: true)
    end

    # @!method string(name, **opt)
    # @!method string!(name, **opt)
    FieldType::ALL.each do |type|
      define_method(type) do |name, **opt, &block|
        self << Field.define(type, name, **opt, &block)
      end

      define_method("#{type}!") do |param_name, **opt, &block|
        send(type, param_name, **opt, required: true, &block)
      end
    end

    # @param [Hash] values
    def cast(values)
      map do |name, field|
        field.cast_with_map(values[name] || values[name.to_sym])
      end.reduce(:merge).compact
    end

    private

    def scoping
      scope.(self.class.name.split("::").last.underscore)
    end

    def <<(field)
      field.scope = scoping
      self[field.name] = field
    end

    def merge(other, **options)
      other_fields = other.is_a?(Hash) ? other : other.list
      other_fields.transform_values! { _1.dup_with(**options) } if options.present?
      self.merge!(other_fields)
    end
  end
end
