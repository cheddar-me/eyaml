# frozen_string_literal: true

module EYAML
  class Util
    class << self
      def pretty_yaml(some_hash)
        some_hash.to_yaml.delete_prefix("---\n")
      end
    end
  end
end
