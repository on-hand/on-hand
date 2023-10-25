# frozen_string_literal: true

module Schema
  class Headers < Fields
    def <<(field)
      field.as ||= field.name.to_s.underscore.split("_").map(&:capitalize).join("-")
      list[field.name] = field
    end
  end
end
