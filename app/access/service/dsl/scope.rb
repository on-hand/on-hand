# frozen_string_literal: true

module Service::Dsl
  class Scope < Array
    def call(*s)
      self.dup.concat(s)
    end

    def service = self[0]
    def lv1_dsl = self[1] # dry, api, task ...
    def lv2_dsl = self[2] # fields, params, headers, response ...

    def schema_type
      (self[3] || lv2_dsl).to_s.singularize.camelize
    end

    def inside_dry?
      lv1_dsl == "dry"
    end

    delegate :configs, :apis, :tasks, :drys, to: :service
  end
end
