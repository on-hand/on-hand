# frozen_string_literal: true

module Service::Action
  class Api
    attr_accessor :name, :http, :path, :configs, :drys
    attr_accessor :params_schema, :headers_schema, :response_schema

    def self.define(name, path, configs:, drys:, &block)
      new.tap do |it|
        a, b       = path.split(" ")
        it.path    = b.nil? ? a : b
        it.http    = b.nil? ? configs._default_http : a.downcase
        it.name    = name
        it.configs = configs || Config.new
        it.drys    = drys || []
        it.instance_eval(&block)

        # should be executed once
        it.params { } unless it.params_schema
        it.headers { } unless it.headers_schema
        it.response { } unless it.response_schema
        it.drys = nil
      end
    end

    def params(&block)
      self.params_schema =
        Schema::Params.define(drys:, &block)
    end

    def headers(&block)
      self.headers_schema =
        Schema::Headers.define(drys:, &block)
    end

    def response(&block)
      self.response_schema =
        Schema::Response.define(drys:, &block)
    end

    # @return [Response]
    def run(params: { }, headers: { }, conn: nil)
      conn ||= Faraday.new(url: configs._base_url)

      Async do
        cast_response conn.public_send(
          http, path,
          params_schema.cast(params),
          headers_schema.cast(headers)
        )
      end.wait
    end

    private

    def cast_response(r)
      Response.new(r).tap do |it|
        it.body = Oj.load(r.body)
        it.data = response_schema&.cast(it.body)
      end
    end

    class Response
      attr_accessor :status, :data, :body

      def initialize(response)
        self.status = response.status
      end
    end
  end
end
