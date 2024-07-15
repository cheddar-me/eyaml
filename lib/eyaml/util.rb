# frozen_string_literal: true

module EYAML
  class Util
    class << self
      def pretty_yaml(some_hash)
        some_hash.to_yaml.delete_prefix("---\n")
      end

      # This will look for any keys that starts with an underscore and duplicates that key-value pair
      # but without the starting underscore.
      # So {_a: "abab"} will become {_a: "abab", a: "abab"}
      # This so we can easilly access our unencrypted secrets without having to add an underscore
      def with_deep_deundescored_keys(hash)
        hash.each_with_object({}) do |pair, total|
          key, value = pair

          value = with_deep_deundescored_keys(value) if value.is_a?(Hash)

          if key.start_with?("_")
            deunderscored_key = key[1..]

            total[deunderscored_key] = value unless total.key?(deunderscored_key)
          end

          total[key] = value
        end
      end
    end
  end
end
