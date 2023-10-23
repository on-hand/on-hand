# frozen_string_literal: true

module Service::Dsl
  class Scope < Struct.new(:service, :dsl, :fields_type, :path)
    delegate :configs, :apis, :tasks, :drys, to: :service

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
      when "Field"    then Schema::Fields.define(scope: self, &block)
      when "Param"    then Schema::Params.define(scope: self, &block)
      when "Header"   then Schema::Headers.define(scope: self, &block)
      when "Response" then Schema::Response.define(scope: self, &block)
      else raise
      end
    end

    def inside_dry?
      dsl == "dry"
    end

    def fields_type=(type)
      super(type.to_s.split("::").last.singularize.camelize)
    end

    def dup
      super.tap do |it|
        it.path = Array.new(path || [ ])
      end
    end
  end
end
