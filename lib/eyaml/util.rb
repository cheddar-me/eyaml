# frozen_string_literal: true

class EYAML
  class Util
    def self.pretty_yaml(some_hash)
      some_hash.to_yaml.delete_prefix("---\n")
    end
  end
end
