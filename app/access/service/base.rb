# frozen_string_literal: true

module Service
  class Base # <- abstract_class
    class << self
      attr_accessor :configs, :drys, :apis, :tasks

      def config(&block)
        self.configs = Dsl::Config.define(&block)
      end

      def api(name, path, &block)
        a, b = path.split
        path = b.nil? ? a : b
        http = b.nil? ? configs._default_http : a.downcase
        apis[name] = Action::Api.define(name:, http:, path:, scope: on("api"), &block)
      end

      def task(name, &block)
        #
      end

      def run(name)
        #
      end

      # --- Dry DSLs --- #

      def dry(&block) =
        self.instance_eval(&block)
      def define(name, &block) =
        drys[name] = on("dry Field").define(&block)
      def params(&block) =
        drys[:params] = on("dry Param").define(&block)
      def headers(&block) =
        drys[:headers] = on("dry Header").define(&block)
      def response(&block) =
        drys[:response] = on("dry Response").define(&block)

      private

      def on(s) = Dsl::Scope.new.(self, *s.split)
    end

    # --- Instance Methods --- #

    attr_accessor :params, :response, :data

    def api(name, *)
      apis.fetch(name).run(*)
    end

    def task(name)
      tasks.fetch(name).run
    end

    def self.inherited(subclass)
      subclass.configs = Dsl::Config.new
      subclass.apis    = OptionHash.new("apis")
      subclass.tasks   = OptionHash.new("tasks")
      subclass.drys    = OptionHash.new(
        { params: { }, headers: { }, response: { } }, "drys")
    end
  end
end
