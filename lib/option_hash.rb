# frozen_string_literal: true

class OptionHash < ActiveSupport::HashWithIndifferentAccess
  def initialize(value = { }, scope)
    super(value) do |slf, excepted_key|
      raise KeyError, "Can not found `#{excepted_key}` in your #{scope}, options: #{slf.keys}"
    end
  end
end
