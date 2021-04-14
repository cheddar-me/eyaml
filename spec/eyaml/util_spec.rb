# frozen_string_literal: true

RSpec.describe EYAML::Util do
  describe ".pretty_yaml" do
    it "will return a hash as YAML without the three dash prefix" do
      yaml_without_prefix = File.read(fixtures_root.join("pretty.yml"))
      expect(EYAML::Util.pretty_yaml({"a" => "1", "b" => "2"})).to eq(yaml_without_prefix)
    end
  end

  describe ".ensure_binary_encoding" do
    let(:utf_8_string) { "abc" }
    let(:binary_string) { "\xAB\xC0".b }

    it "returns a string in binary encoding" do
      expect(EYAML::Util.ensure_binary_encoding(utf_8_string)).to eq(binary_string)
      expect(EYAML::Util.ensure_binary_encoding(utf_8_string).encoding).to eq(Encoding::BINARY)
    end

    it "returns the provided string if it's already binary encoded" do
      expect(EYAML::Util.ensure_binary_encoding(binary_string)).to eq(binary_string)
    end
  end
end
