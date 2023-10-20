# frozen_string_literal: true

module Service
  class Config
    attr_accessor :_base_url, :login_method, :must_login

    def initialize
      self._base_url = ""
    end

    def self.define(&block)
      new.tap { _1.instance_eval(&block) }
    end

    def base_url(value)
      self._base_url = value
    end
  end
end
