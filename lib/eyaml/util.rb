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
          case value
          when Hash
            child_hash = with_deep_deundescored_keys(value)

            if key.start_with?("_")
              raise KeyError, "De-underscored key '#{key[1..]}' already exists." if total.key?(key[1..])

              total[key[1..]] = child_hash
            end

            total[key] = child_hash
          else
            if key.start_with?("_")
              raise KeyError, "De-underscored key '#{key[1..]}' already exists." if total.key?(key[1..])

              total[key[1..]] = value
            end
            total[key] = value
          end
        end
      end
    end
  end
end
