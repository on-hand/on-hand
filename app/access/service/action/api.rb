# frozen_string_literal: true

module Service::Action
  class Api < Struct.new(
    :name, :http, :base_url, :path, :scope,
    :param_schema, :header_schema, :response_schema
  )
    def self.define(name:, http:, path:, scope:, &block)
      new(
        name:, http:, path:, scope:, base_url: scope.configs._base_url
      ).tap { _1.instance_eval(&block) }
    end

    def params(&block) =
      self.param_schema = scope.("Param").define(&block)
    def headers(&block) =
      self.header_schema = scope.("Header").define(&block)
    def response(&block) =
      self.response_schema = scope.("Response").define(&block)

    # @return [Response]
    def run(params: { }, headers: { }, conn: nil)
      conn ||= Faraday.new(url: base_url)

      Async do
        cast_response conn.public_send(
          http, path,
          param_schema.cast(params),
          header_schema.cast(headers)
        )
      end.wait
    end

    def param_schema = super || params { }
    def header_schema = super || headers { }
    def response_schema = super || response { }

    private

    def cast_response(r)
      Response.new(r).tap { _1.schema = response_schema }
    end

    class Response
      attr_accessor :status, :raw_body, :schema

      def initialize(response)
        self.status = response.status
        self.raw_body = Oj.load(response.body) # TODO: Oj error
      end
      
      def body
        @body ||= schema.cast(raw_body, type: :api)
      end

      def to_save
        @to_save ||= schema.casted_to_save(body)
      end

      def save
        #
      end
    end
  end
end
