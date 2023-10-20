# frozen_string_literal: true

module Service
  class Base
    class << self
      attr_accessor :configs, :drys, :apis, :tasks

      def config(&block)
        self.configs = Config.define(&block)
      end

      def dry(&block)
        #
      end

      def api(name, path, &block)
        (self.apis ||= { })[name] =
          Api.define(name, path, configs:, drys:, &block)
      end

      def task(name, &block)
        #
      end

      def run(name)
        #
      end
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
