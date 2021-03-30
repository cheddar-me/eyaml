# frozen_string_literal: true

require "thor"
require "rbnacl"
require "base64"
require "yaml"
require "json"
require "pathname"

require "pry"

class EYAML
  class Error < StandardError; end
  DEFAULT_KEYDIR = "/opt/ejson/keys"
  INTERNAL_PUB_KEY = "_public_key"

  class << self
    def generate_keypair
      EncryptionManager.new_keypair
    end

    def encrypt(plaindata, keydir:)
      public_key = plaindata.fetch(INTERNAL_PUB_KEY)
      private_key = load_private_key_from(public_key: public_key, keydir: keydir)

      encryption_manager = EncryptionManager.new(plaindata, public_key, private_key)
      encryption_manager.encrypt
    end

    def encrypt_file_in_place(file_path, keydir:, output_format: :yaml)
      plaindata = YAML.load_file(file_path)
      cipherdata = encrypt(plaindata, keydir: keydir)

      eyaml = if output_format == :json
        JSON.pretty_generate(cipherdata)
      else
        EYAML::Util.pretty_yaml(cipherdata)
      end

      File.write(file_path, eyaml)
      eyaml.bytesize
    end

    def decrypt(cipherdata, **key_options)
      public_key = cipherdata.fetch(INTERNAL_PUB_KEY)
      private_key = load_private_key_from(public_key: public_key, **key_options)

      encryption_manager = EncryptionManager.new(cipherdata, public_key, private_key)
      encryption_manager.decrypt
    end

    def decrypt_file(file_path, **key_options)
      cipherdata = YAML.load_file(file_path)
      decrypt(cipherdata, **key_options)
    end

    private

    def load_private_key_from(public_key:, keydir: nil, private_key: nil)
      raise ArgumentError, "One of :keydir or :private_key must be set" if keydir.nil? && private_key.nil?

      return private_key unless private_key.nil?
      File.read(File.expand_path(public_key, keydir))
    end
  end
end

require_relative "eyaml/version"
require_relative "eyaml/util"
require_relative "eyaml/cli"
require_relative "eyaml/encryption_manager"
