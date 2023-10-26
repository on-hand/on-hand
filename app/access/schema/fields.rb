# frozen_string_literal: true

module Schema
  class Fields < Struct.new(:list, :scope, :persistence)
    delegate :[], :[]=, :fetch, :map, :each, :blank?, :present?, to: :list

    def initialize(**)
      super(**)
      self.list = { }.with_indifferent_access
      self.persistence ||= Persistence.new
    end

    def self.define(scope:, **, &block)
      fields = new(scope:, **)
      case returned = fields.instance_eval(&block)
      in Schema::Fields
        fields = returned.dup_with(scope:)
      in String|Symbol|[ String|Symbol, * ]
        fields.use(*Array(returned))
      in Hash|[ Hash, * ]
        3
      else; nil
      end

      fields.tap do |it|
        # auto-use default dry block
        case it.class.name
        when /Params/   then it.use(:params)
        when /Headers/  then it.use(:headers)
        when /Response/ then it.use(:response)
        end unless scope.inside_dry?
      end
    end

    def use(*names, **)
      names.each do |name|
        scope = self.scope.dup.tap { _1.fields_type = self.class.name }
        merge(scope.drys.fetch(name), **, scope:)
      end; nil
    end

    def use!(*names)
      use(*names, required: true); nil
    end

    # @!method string(name, **opt)
    # @!method string!(name, **opt)
    FieldType::ALL.each do |type|
      define_method(type) do |name, **opt, &block|
        self << Field.define(
          type:, name:, persistence:, scope: scope.(name:), **opt, &block)
      end

      define_method("#{type}!") do |param_name, **opt, &block|
        send(type, param_name, **opt, required: true, &block)
      end
    end

    # @param [Hash] values
    # TODO: html
    def cast(values, type: :api)
      values = { } if values.nil?
      map do |name, field|
        field.cast_with_name(values[name] || values[name.to_sym])
      end.reduce(:merge).compact.with_indifferent_access
    end

    def casted_to_save(casted)
      persistence.cast(casted)
    end

    def dup_with(**)
      self.dup.tap do |it|
        it.each { it[_1] = _2.dup_with(**) }
      end
    end

    private

    def <<(field)
      self[field.name] = field
    end

    def merge(other, **)
      return if other.blank?

      self.persistence.merge!(other.persistence)
      self.list.merge!(other.dup_with(persistence:, **).list)
    end
  end
end
