# frozen_string_literal: true

module Service
  class Api
    attr_accessor :name, :http, :path
    attr_accessor :_params, :_response, :configs, :drys

    def self.define(name, path, configs:, drys:, &block)
      api         = new
      api.name    = name
      api.configs = configs || Config.new
      api.drys    = drys || [ ]

      a, b = path.split(" ")
      api.path = b.nil? ? a : b
      api.http = b.nil? ? "get" : a.downcase
      if %w[ get post ].exclude?(api.http)
        raise NotImplementedError, "HTTP method #{api.http} is not implemented"
      end

      api.tap { _1.instance_eval(&block) }
    end

    def params(&block)
      self._params =
        Schema::Params.define(drys:, &block)
    end

    def response(&block)
      self._response =
        Schema::Response.define(drys:, &block)
    end

    # @return [Response]
    def run(params: { }, headers: { }, conn: nil)
      conn ||= Faraday.new(url: configs._base_url)

      Async do
        cast_response conn.public_send(
          http, path, cast_params(params), headers
        )
      end.wait
    end

    private

    def cast_params(values)
      _params.cast(values)
    end

    def cast_response(r)
      Response.new(r).tap do |it|
        it.data = _response.cast(Oj.load(r.body))
      end
    end

    class Response
      attr_accessor :status, :data, :response

      def initialize(response)
        self.status   = response.status
        self.response = response.body
      end
    end
  end
end
