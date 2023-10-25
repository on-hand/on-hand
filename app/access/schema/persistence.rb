# frozen_string_literal: true

module Schema
  class Persistence < Struct.new(:array, :uid_path)
    def initialize
      self.uid_path = [ ]
    end

    def merge!(other)
      self.array ||= other.array
      self.uid_path = other.uid_path if other.uid_path.present?
    end

    def cast(hash)
      Helper.dig(
        *uid_path[..-2], %i[ uid title ], on: hash
      ).presence \
        or raise Error, "Persistence: `#{uid_path.join('.')}` not found"
    end

    def validate_self
      raise Error, "Persistence: `uid` not defined" if uid_path.blank?
    end

    class Error < StandardError; end

    # TODO: refactor
    class Helper
      def self.dig(*keys, last, on:)
        result = on
        keys.each do |key|
          if result.is_a?(Array)
            result = result.map { _1[key] }
          elsif key.end_with?("[]")
            result = result[key[..-3]]
            return nil if result.blank?# || !result.is_a?(Array) || !result.all?(Hash)
          else
            result = result[key]
            return nil if result.blank? || !result.is_a?(Hash)
          end
        end

        if result.is_a?(Hash)
          result.slice(*Array(last))
        else
          result.map { _1.slice(*Array(last)) }
        end
      end
    end
  end
end
