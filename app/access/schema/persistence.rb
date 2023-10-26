# frozen_string_literal: true

module Schema
  class Persistence < Struct.new(:array, :path)
    def initialize
      self.path = {
        uid: nil,
        title: nil,
        content: nil,
      }
    end

    def merge!(other)
      self.array ||= other.array
      self.path.merge!(other.path) do |key, a, b|
        b.present? ? b : a
      end
    end

    def detect_defined(name:, scope:)
      if name.to_sym.in?(%i[ uid title content ])
        self.path[name.to_sym] = scope.path_aliases[..-2]
      end
    end

    # TODO: refactor
    def cast(hash)
      validate_self
      ne_uid_level = Helper.dig_reduce(casting_path[:ne_uid_level], on: hash)
      casted = Helper.dig(*casting_path[:uid_level].values, on: hash)
      lt_uid_level = Helper.dig_reduce(casting_path[:lt_uid_level], on: hash)

      if casted.is_a?(Array)
        not_found!(:uid) if casted.any? { _1[:uid].blank? }
        casted.each_with_index do |v, i|
          v.merge!(ne_uid_level) # TODO: support array
          v.merge!(lt_uid_level[i]) if lt_uid_level[i].present?
        end
      else
        not_found!(:uid) if casted[:uid].blank?
        casted.merge!(ne_uid_level)
        casted.merge!(lt_uid_level)
      end
      casted
    end

    def validate_self
      return if @validated
      raise Error, "Persistence: `uid` not defined" if path[:uid].nil?
      @validated = true
    end

    def casting_path
      @casting_path ||= {
        ne_uid_level: level("!=", :uid),
        uid_level:    level(:uid),
        lt_uid_level: level("<", :uid)
      }
    end

    private

    # TODO: refactor
    def level(op = "=", key)
      p = path[key]
      case op
      when "="
        { path: p, keys: path.select { _2 == p }.keys }
      when "<"
        keys = path.select { _2 != p and _2 & p == p }.keys
        path.slice(*keys).group_by { _2 }.map do |k, v|
          # { path: k - p, keys: Hash[v].keys }
          { path: k, keys: Hash[v].keys }
        end
      else
        keys = path.select { !_2.nil? and _2 != p and _2 & p != p }.keys
        path.slice(*keys).group_by { _2 }.map do |k, v|
          { path: k, keys: Hash[v].keys }
        end
      end
    end

    def not_found!(key)
      raise Error, "Persistence: `#{path[key].join('.')}` not found"
    end

    class Error < StandardError; end

    # TODO: refactor
    # @return [Hash] or [Array<Hash>]
    #   eg. [{ uid: .. }..]
    class Helper
      def self.dig(*keys, last, on:)
        result = on
        keys = keys.flatten if keys.first.is_a?(Array)
        keys.each do |key|
          if result.is_a?(Array)
            key = key[..-3] if key.end_with?("[]")
            result = result.map { _1[key] }
          elsif key.end_with?("[]")
            result = result[key[..-3]]
            return nil if result.blank?# || !result.is_a?(Array) || !result.all?(Hash)
          else
            result = result[key]
            return nil if result.blank? || !result.is_a?(Hash)
          end
        end

        last = Array(last)
        case result
        in Hash
          result.slice(*last)
        in [[Hash, *], *]
          result.map do |r|
            keys = { }
            r.each do |rr|
              last.each do |key|
                (keys[key] ||= [ ]) << rr[key]
              end
            end
            keys
          end
        else
          result.map { _1.slice(*last) }
        end
      end

      def self.dig_reduce(info, on:)
        info.map do
          Helper.dig(*_1.values, on:) if _1.present?
        end.compact.reduce do |a, b|
          if a.is_a?(Array)
            a.map.with_index { _1.merge(b[_2]) }
          else
            a.merge(b)
          end
        end || { }
      end
    end
  end
end
