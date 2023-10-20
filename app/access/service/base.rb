# frozen_string_literal: true

module Service
  class Base
    class << self
      attr_accessor :configs, :drys, :apis, :tasks

      def config(&block)
        self.configs = Config.define(&block)
      end

      def api(name, path, &block)
        self.apis ||= { }.with_indifferent_access
        apis[name] = Action::Api.define(name, path, configs:, drys:, &block)
      end

      def task(name, &block)
        #
      end

      def run(name)
        #
      end

      # --- Dry DSLs --- #

      def dry(&block)
        self.drys = {
          params: { }, headers: { }, response: { }
        }.with_indifferent_access
        self.instance_eval(&block)
      end

      def define(name, &block) =
        drys[name] = Schema::Base.define(&block)
      def params(&block) =
        drys[:params] = Schema::Params.define(&block)
      def headers(&block) =
        drys[:headers] = Schema::Headers.define(&block)
      def response(&block) =
        drys[:response] = Schema::Response.define(&block)
    end

    # --- Instance Methods --- #

    attr_accessor :params, :response, :data

    def api(name, *)
      apis.fetch(name).run(*)
    end

    def task(name)
      tasks.fetch(name).run
    end
  end
end
