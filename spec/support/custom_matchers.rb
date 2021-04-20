# frozen_string_literal: true

RSpec::Matchers.define :be_json do
  match do |actual|
    !!JSON.parse(actual)
  rescue JSON::ParserError
    false
  end
end

RSpec::Matchers.define :be_yaml do
  match do |actual|
    expect(actual).not_to be_json
    !!YAML.safe_load(actual)
  rescue Psych::SyntaxError
    false
  end
end

RSpec::Matchers.define :be_a_json_file do
  match do |actual|
    file_contents = File.read(actual)
    expect(file_contents).to be_json
  end
end

RSpec::Matchers.define :be_a_yaml_file do
  match do |actual|
    file_contents = File.read(actual)
    expect(file_contents).to be_yaml
  end
end

RSpec::Matchers.define :be_public_key_of do |priv_key|
  match do |pub_key|
    priv_key_bin = RbNaCl::Util.hex2bin(priv_key)
    private_key = RbNaCl::Boxes::Curve25519XSalsa20Poly1305::PrivateKey.new(priv_key_bin)

    public_key_hex = RbNaCl::Util.bin2hex(private_key.public_key)
    expect(public_key_hex).to eq(pub_key)
  end
end
