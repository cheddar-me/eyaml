# frozen_string_literal: true

require "spec_helper"

RSpec.describe EYAML do
  include EncryptionHelper
  include FileHelper

  describe ".generate_keypair" do
    it "returns a public/private key pair" do
      public_key, private_key = EYAML.generate_keypair

      expect(public_key).not_to be nil
      expect(private_key).not_to be nil

      expect(public_key).to be_public_key_of(private_key)
    end

    it "will return keys encoded in ASCII" do
      public_key, private_key = EYAML.generate_keypair

      expect(public_key.encoding).to be Encoding::ASCII
      expect(private_key.encoding).to be Encoding::ASCII
    end

    describe "will save the keys when 'save' argument is true" do
      it "to /opt/ejson/keys by default" do
        current_keys_count = Dir[File.join(default_keydir, "*")].count

        EYAML.generate_keypair(save: true)

        expect(Dir[File.join(default_keydir, "*")].count).to eq(current_keys_count + 1)
      end

      it "to $EJSON_KEYDIR when it's set" do
        allow(ENV).to receive(:[]).with("EJSON_KEYDIR").and_return(test_keydir)
        expect(Dir.empty?(test_keydir)).to be true

        EYAML.generate_keypair(save: true)
        expect(Dir.empty?(test_keydir)).to be false
      end

      it "to the directory set by the 'keydir' argument" do
        expect(Dir.empty?(test_keydir)).to be true
        EYAML.generate_keypair(save: true, keydir: test_keydir)
        expect(Dir.empty?(test_keydir)).to be false
      end
    end
  end

  describe ".encrypt" do
    it "walks through the provided yaml and encrypts each un-encrypted hash value" do
      expect(EYAML.encrypt(data)["s3cr3t"]).to match(encrypted_value_regex)
    end

    it "encrypts the tree of hashes even if the parent key has an underscore" do
      expect(EYAML.encrypt(data).dig("_dont_skip_me", "another_secret")).to match(encrypted_value_regex)
    end

    it "skips encrypting any values who's keys start with an underscore" do
      expect(EYAML.encrypt(data)["_skip_me"]).to eq("not_secret")
    end

    it "reads the public key from the hash key '_public_key'" do
      expect(File).to receive(:read).with(
        File.join(default_keydir, data.fetch("_public_key"))
      ).and_return(private_key)
      EYAML.encrypt(data)
    end

    it "it defaults to reading the private key from the ENV $EJSON_KEYDIR if it's set" do
      allow(ENV).to receive(:[]).with("EJSON_KEYDIR").and_return(test_keydir)
      expect(File).to receive(:read).with(
        File.join(test_keydir, public_key)
      ).and_return(private_key)

      EYAML.encrypt(data)
    end

    it "it will read a private key from the provided 'keydir'" do
      expect(File).to receive(:read).with(
        File.join(test_keydir, public_key)
      ).and_return(private_key)
      EYAML.encrypt(data, keydir: test_keydir)
    end

    it "it defaults to reading the private key from /opt/ejson/keys" do
      expect(File).to receive(:read).with(public_key_path).and_return(private_key)
      EYAML.encrypt(data)
    end

    context "missing '_public_key' key" do
      let(:data) {
        {"secret" => "EJ[1:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]"}
      }

      it "errors when '_public_key' isn't set" do
        expect { EYAML.encrypt(data) }.to raise_error(EYAML::MissingPublicKey)
      end
    end
  end

  describe ".decrypt" do
    it "returns a hash with every encrypted value, decrypted" do
      expect(EYAML.decrypt(data)["secret"]).to eq("password")
    end

    it "reads the public key from the hash key '_public_key'" do
      expect(File).to receive(:read).with(
        File.join(default_keydir, data.fetch("_public_key"))
      ).and_return(private_key)
      expect(EYAML.decrypt(data)["secret"]).to eq("password")
    end

    it "accepts a private key for decrypting the data" do
      File.delete(public_key_path)
      expect(EYAML.decrypt(data, private_key: private_key)["secret"]).to eq("password")
    end

    it "it defaults to reading the private key from the ENV $EJSON_KEYDIR if it's set" do
      allow(ENV).to receive(:[]).with("EJSON_KEYDIR").and_return(test_keydir)
      expect(File).to receive(:read).with(
        File.join(test_keydir, public_key)
      ).and_return(private_key)
      EYAML.decrypt(data)
    end

    it "it will read a private key from the provided 'keydir'" do
      expect(File).to receive(:read).with(
        File.join(test_keydir, public_key)
      ).and_return(private_key)
      EYAML.decrypt(data, keydir: test_keydir)
    end

    it "it defaults to reading the private key from /opt/ejson/keys" do
      expect(File).to receive(:read).with(public_key_path).and_return(private_key)
      EYAML.decrypt(data)
    end

    context "missing '_public_key' key" do
      let(:data) {
        {"secret" => "EJ[1:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]"}
      }

      it "errors when '_public_key' isn't set" do
        expect { EYAML.decrypt(data) }.to raise_error(EYAML::MissingPublicKey)
      end
    end
  end

  describe ".encrypt_file_in_place" do
    it "encrypts the specified file" do
      test_file = fixtures_root.join("data.eyaml")
      plain_secret_value = YAML.load_file(test_file).fetch("s3cr3t")
      expect(plain_secret_value).to match("p4ssw0rd")

      EYAML.encrypt_file_in_place(test_file)

      cipher_secret_value = YAML.load_file(test_file).fetch("s3cr3t")
      expect(cipher_secret_value).to match(encrypted_value_regex)
    end

    it "formats the output as JSON if the file extension is .ejson" do
      test_file = duplicate_fixture_with_new_ext("eyaml", "ejson")
      expect(test_file).to be_a_yaml_file

      EYAML.encrypt_file_in_place(test_file)

      expect(test_file).to be_a_json_file
    end

    it "formats the output as YAML if the file extension is .eyaml" do
      test_file = duplicate_fixture_with_new_ext("ejson", "eyaml")
      expect(test_file).to be_a_json_file

      EYAML.encrypt_file_in_place(test_file)

      expect(test_file).to be_a_yaml_file
    end

    it "formats the output as YAML if the file extension is .eyml" do
      test_file = duplicate_fixture_with_new_ext("ejson", "eyml")
      expect(test_file).to be_a_json_file

      EYAML.encrypt_file_in_place(test_file)

      expect(test_file).to be_a_yaml_file
    end
  end

  describe ".decrypt_file" do
    it "decrypts the specified file" do
      test_file = fixtures_root.join("data.ejson")
      expect(EYAML.decrypt_file(test_file)).to eq(
        JSON.pretty_generate(
          # We need to update data to contain only decrypted values
          data.merge({"secret" => "password"})
        )
      )
    end

    it "formats the output as JSON if the file extension is .ejson" do
      test_file = duplicate_fixture_with_new_ext("eyaml", "ejson")
      expect(test_file).to be_a_yaml_file
      expect(EYAML.decrypt_file(test_file)).to be_json
    end

    it "formats the output as YAML if the file extension is .eyaml" do
      test_file = duplicate_fixture_with_new_ext("ejson", "eyaml")
      expect(test_file).to be_a_json_file
      expect(EYAML.decrypt_file(test_file)).to be_yaml
    end

    it "formats the output as YAML if the file extension is .eyml" do
      test_file = duplicate_fixture_with_new_ext("ejson", "eyml")
      expect(test_file).to be_a_json_file
      expect(EYAML.decrypt_file(test_file)).to be_yaml
    end
  end
end
