# frozen_string_literal: true

module Service::Action
  class Api < Struct.new(
    :name, :http, :base_url, :path, :scope,
    :param_fields, :header_fields, :response_fields
  )
    def self.define(name:, http:, path:, scope:, &block)
      new(
        name:, http:, path:, scope:, base_url: scope.configs._base_url
      ).tap do |it|
        it.instance_eval(&block)
        # should be executed once
        it.params { } unless it.param_fields
        it.headers { } unless it.header_fields
        it.response { } unless it.response_fields
      end
    end

    def params(&block)
      self.param_fields =
        Schema::Params.define(scope: scope.("params"), &block)
    end

    def headers(&block)
      self.header_fields =
        Schema::Headers.define(scope: scope.("headers"), &block)
    end

    def response(&block)
      self.response_fields =
        Schema::Response.define(scope: scope.("response"), &block)
    end

    # @return [Response]
    def run(params: { }, headers: { }, conn: nil)
      conn ||= Faraday.new(url: base_url)

      Async do
        cast_response conn.public_send(
          http, path,
          param_fields.cast(params),
          header_fields.cast(headers)
        )
      end.wait
    end

    private

    def cast_response(r)
      Response.new(r).tap do |it|
        it.body = Oj.load(r.body)
        it.data = response_fields&.cast(it.body)
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
