# frozen_string_literal: true

module EYAML
  class Util
    class << self
      def pretty_yaml(some_hash)
        some_hash.to_yaml.delete_prefix("---\n")
      end

      def ensure_binary_encoding(str)
        if str.encoding == Encoding::BINARY
          return str
        end

        RbNaCl::Util.hex2bin(str)
      end
    end
  end
end
