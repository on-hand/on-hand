# frozen_string_literal: true

module Service::Dsl
  class Config
    attr_accessor :_base_url, :_default_http

    def initialize
      self._base_url = ""
      self._default_http = "get"
    end

    def self.define(&block)
      new.tap { _1.instance_eval(&block) }
    end

    def base_url(value)     = self._base_url = value
    def default_http(value) = self._default_http = value
  end
end
