# frozen_string_literal: true

module Service
  class Base # <- abstract_class
    class << self
      attr_accessor :configs, :drys, :apis, :tasks

      def config(&block)
        self.configs = Dsl::Config.define(&block)
      end

      def api(name, path, &block)
        a, b  = path.split(" ")
        path  = b.nil? ? a : b
        http  = b.nil? ? configs._default_http : a.downcase
        scope = self.scope("api")
        apis[name] = Action::Api.define(name:, http:, path:, scope:, &block)
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
        drys[name] = Schema::Fields.define(scope: scope("dry", "fields"), &block)
      def params(&block) =
        drys[:params] = Schema::Params.define(scope: scope("dry", "params"), &block)
      def headers(&block) =
        drys[:headers] = Schema::Headers.define(scope: scope("dry", "headers"), &block)
      def response(&block) =
        drys[:response] = Schema::Response.define(scope: scope("dry", "response"), &block)

      private

      def scope(*s) = Dsl::Scope.new([ self, *s ])
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
      subclass.apis  = { }.with_indifferent_access
      subclass.tasks = { }.with_indifferent_access
      subclass.drys  = {
        params: { }, headers: { }, response: { }
      }.with_indifferent_access
    end
  end
end
