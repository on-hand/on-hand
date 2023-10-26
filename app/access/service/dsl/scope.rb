# frozen_string_literal: true

module Service::Dsl
  class Scope < Struct.new(:service, :dsl, :fields_type, :path)
    delegate :configs, :apis, :tasks, :drys, to: :service

    # @example api_scope.("Response")
    # @example response_scope.(name: "result", array: true)
    def call(*args)
      self.dup.tap do |it|
        args.each do |arg|
          if it.service.nil?
            it.service = arg
          elsif it.dsl.nil?
            it.dsl = arg
          elsif it.fields_type.nil?
            it.fields_type = arg
          else
            it.path << arg
          end
        end
      end
    end

    def define(**, &block)
      case fields_type
      when "Field"    then Schema::Fields.define(scope: self, **, &block)
      when "Param"    then Schema::Params.define(scope: self, **, &block)
      when "Header"   then Schema::Headers.define(scope: self, **, &block)
      when "Response" then Schema::Response.define(scope: self, **, &block)
      else raise
      end
    end

    def inside_dry?
      dsl == "dry"
    end

    def fields_type=(type)
      super(type.to_s.split("::").last.singularize.camelize)
    end

    def path_names
      @path_names ||= path.map { _1[:array] ? "#{_1[:name]}[]" : "#{_1[:name]}" }
    end

    def path_aliases
      @path_aliases ||= path.map do
        name = _1[:as] || _1[:name]
        _1[:array] ? "#{name}[]" : "#{name}"
      end
    end

    def path_inspect
      path_names.join(".")
    end

    def dup
      super.tap do |it|
        it.path = Array.new(path || [ ])
      end
    end
  end
end
