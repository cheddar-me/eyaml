# frozen_string_literal: true

RSpec.describe EYAML::EncryptionManager do
  include EncryptionHelper

  describe ".new_keypair" do
    it "returns a Curve25519XSalsa20Poly1305 public/private key pair" do
      pub_key, priv_key = EYAML::EncryptionManager.new_keypair

      expect(pub_key).not_to be nil
      expect(priv_key).not_to be nil

      expect(pub_key).to be_public_key_of(priv_key)
    end

    it "will return keys encoded in ASCII" do
      pub_key, priv_key = EYAML::EncryptionManager.new_keypair

      expect(pub_key.encoding).to be Encoding::ASCII
      expect(priv_key.encoding).to be Encoding::ASCII
    end
  end

  subject do
    EYAML::EncryptionManager.new(data, public_key, private_key)
  end

  describe "#decrypt" do
    let(:data) {
      {
        "_public_key" => public_key,
        "secret" => "EJ[1:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]",
        "s3cr3t" => "p4ssw0rd",
        "_secret" => "EJ[1:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]"
      }
    }

    it "walks through the provided yaml and decrypts each encrypted hash value" do
      expect(subject.decrypt).to include("secret" => "password")
    end

    it "leaves decrypted values as they are" do
      expect(subject.decrypt).to include("s3cr3t" => data["s3cr3t"])
    end

    it "doesn't touch values with an underscore in their key" do
      expect(subject.decrypt).to include("_secret" => data["_secret"])
    end

    context "invalid EJSON format version" do
      let(:data) {
        {
          "_public_key" => public_key,
          "secret" => "EJ[2:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]"
        }
      }

      it "errors if an encrypted value with a format version that isn't v1" do
        expect { subject.decrypt }.to raise_error(EYAML::UnsupportedVersionError)
      end
    end
  end

  describe "#encrypt" do
    let(:data) {
      {
        "_public_key" => public_key,
        "secret" => "EJ[1:egJgZHLIZfR836f9cOM7g49aPELl7ZgKRz7oDNGLa3s=:1NucdUwyqVGtv7Vj7fH7hfWzg70wUbKn:N5adZhS8xuySyQ2MvY7f027p0VqO3Qeb]",
        "s3cr3t" => "p4ssw0rd",
        "_skip_me" => "not_secret",
        "_dont_skip_me" => {
          "another_secret" => "ssshhh"
        }
      }
    }

    it "walks through the provided yaml and encrypts each un-encrypted hash value" do
      expect(subject.encrypt["s3cr3t"]).to match(/\AEJ\[[\w:\/+=]+\]\z/)
    end

    it "will skip encrypting values that are already encrypted" do
      expect(subject.encrypt).to include("secret" => data["secret"])
    end

    it "will skip encrypting values that have a key prefixed with an underscore" do
      expect(subject.encrypt).to include("_skip_me" => "not_secret")
    end

    it "will encrypt subtrees even if the key is prefixed with an underscore" do
      expect(subject.encrypt.dig("_dont_skip_me", "another_secret")).to match(/\AEJ\[[\w:\/+=]+\]\z/)
    end

    it "encrypts values with the EJSON v1 format" do
      expect(subject.encrypt["s3cr3t"]).to match(/\AEJ\[1:/)
    end
  end
end
