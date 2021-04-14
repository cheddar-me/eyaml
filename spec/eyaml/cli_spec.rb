# frozen_string_literal: true

RSpec.describe EYAML::CLI do
  include EncryptionHelper

  let(:test_file) { fixtures_root.join("data.eyaml") }

  describe "#encrypt" do
    it "encrypts the provided file" do
      plain_secret_value = YAML.load_file(test_file).fetch("s3cr3t")
      expect(plain_secret_value).to match("p4ssw0rd")

      EYAML::CLI.start(["encrypt", test_file])

      cipher_secret_value = YAML.load_file(test_file).fetch("s3cr3t")
      expect(cipher_secret_value).to match(encrypted_value_regex)
    end

    it "encrypts multiple files when they're provided" do
      test_files = [
        fixtures_root.join("data.eyaml"),
        fixtures_root.join("data.ejson")
      ]

      test_files.each do |file|
        plain_secret_value = YAML.load_file(file).fetch("s3cr3t")
        expect(plain_secret_value).to match("p4ssw0rd")
      end

      EYAML::CLI.start(["encrypt", *test_files])

      test_files.each do |file|
        cipher_secret_value = YAML.load_file(file).fetch("s3cr3t")
        expect(cipher_secret_value).to match(encrypted_value_regex)
      end
    end
  end

  describe "#decrypt" do
    it "decrypts the provided file and prints it" do
      cipherdata = YAML.load_file(test_file)
      expect(cipherdata.fetch("secret")).not_to eq("password")
      expect do
        EYAML::CLI.start(["decrypt", test_file])
      end.to output(/secret: password/).to_stdout
    end

    describe "--output" do
      it "outputs the decrypted data to the provided file, rather than stdout" do
        target_file = fixtures_root.join("output.yml")
        target_file_path = Pathname.new(target_file)

        expect(target_file_path.exist?).to be false
        expect do
          EYAML::CLI.start(["decrypt", "--output=#{target_file}", test_file])
        end.not_to output.to_stdout

        cipherdata = YAML.load_file(target_file)
        expect(cipherdata.fetch("secret")).to eq("password")
      end
    end

    describe "--key-from-stdin" do
      it "reads the private key from STDIN" do
        File.delete(public_key_path)
        cipherdata = YAML.load_file(test_file)
        expect(cipherdata.fetch("secret")).not_to eq("password")

        allow($stdin).to receive(:gets) { private_key }
        expect do
          EYAML::CLI.start(["decrypt", "--key-from-stdin", test_file])
        end.to output(/secret: password/).to_stdout
      end

      it "ignores --keydir if it's also set" do
        allow($stdin).to receive(:gets) { private_key }
        expect(File).not_to receive(:read).with(
          File.join(test_keydir, public_key)
        )
        EYAML::CLI.start(["decrypt", "--key-from-stdin", "--keydir=#{test_keydir}", test_file])
      end
    end
  end

  describe "#keygen" do
    it "generates a new EYAML keypair" do
      expect do
        EYAML::CLI.start(["keygen"])
      end.to output(/\APublic Key: \w+\nPrivate Key: \w+\n\z/).to_stdout
    end

    describe "--write saves the generated EYAML keypair" do
      it "to /opt/ejson/keys by default" do
        current_keys_count = Dir[File.join(default_keydir, "*")].count
        expect do
          EYAML::CLI.start(["keygen", "--write"])
        end.to output(/\APublic Key: \w+\n\z/).to_stdout
        expect(Dir[File.join(default_keydir, "*")].count).to eq(current_keys_count + 1)
      end

      it "to $EJSON_KEYDIR when it's set" do
        allow(ENV).to receive(:[]).with("EJSON_KEYDIR").and_return(test_keydir)
        expect(Dir.empty?(test_keydir)).to be true
        EYAML::CLI.start(["keygen", "--write"])
        expect(Dir.empty?(test_keydir)).to be false
      end

      it "to the directory set by --keydir" do
        expect(Dir.empty?(test_keydir)).to be true
        EYAML::CLI.start(["keygen", "--write", "--keydir", test_keydir])
        expect(Dir.empty?(test_keydir)).to be false
      end
    end
  end

  describe "--keydir" do
    it "sets the key directory when decrypting a file" do
      expect(File).to receive(:read).with(
        File.join(test_keydir, public_key)
      ).and_return(private_key)

      EYAML::CLI.start(["decrypt", "--keydir=#{test_keydir}", test_file])
    end
  end
end
