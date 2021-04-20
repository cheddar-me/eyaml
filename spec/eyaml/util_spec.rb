# frozen_string_literal: true

RSpec.describe EYAML::Util do
  describe ".pretty_yaml" do
    it "will return a hash as YAML without the three dash prefix" do
      yaml_without_prefix = File.read(fixtures_root.join("pretty.yml"))
      expect(EYAML::Util.pretty_yaml({"a" => "1", "b" => "2"})).to eq(yaml_without_prefix)
    end
  end
end
