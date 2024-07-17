# frozen_string_literal: true

RSpec.describe EYAML::Util do
  describe ".pretty_yaml" do
    it "will return a hash as YAML without the three dash prefix" do
      yaml_without_prefix = File.read(fixtures_root.join("pretty.yml"))
      expect(EYAML::Util.pretty_yaml({"a"=>"1", "b"=>"2", "_c"=>{"_d"=>"3"}})).to eq(yaml_without_prefix)
    end
  end

  describe ".with_deep_deundescored_keys" do
    it "will return a hash with all undescored entries duplicated" do
      yaml_without_prefix = YAML.load_file(fixtures_root.join("pretty.yml"))

      expect(EYAML::Util.with_deep_deundescored_keys(yaml_without_prefix)).to eq({"a"=>"1", "b"=>"2", "c"=>{"d"=>"3", "_d"=>"3"}, "_c"=>{"d"=>"3", "_d"=>"3"}})
    end

    it "will raise when a de-underscored key already exists" do
      yaml_without_prefix = YAML.load_file(fixtures_root.join("pretty.yml")).merge("_b" => "X")

      expect { EYAML::Util.with_deep_deundescored_keys(yaml_without_prefix) }.to raise_error(KeyError)
    end
  end
end
