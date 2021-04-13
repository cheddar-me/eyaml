# frozen_string_literal: true

require "thor"
require "rbnacl"
require "base64"
require "yaml"
require "json"
require "pathname"

module EYAML
  class MissingPublicKey < StandardError; end

  DEFAULT_KEYDIR = "/opt/ejson/keys"
  INTERNAL_PUB_KEY = "_public_key"

  class << self
    def generate_keypair(save: false, keydir: nil)
      public_key, private_key = EncryptionManager.new_keypair

      if save
        keypair_file_path = File.expand_path(public_key, ensure_keydir(keydir))
        File.write(keypair_file_path, private_key)
      end

      [public_key, private_key]
    end

    def encrypt(plaindata, keydir: nil)
      public_key = load_public_key(plaindata)
      private_key = load_private_key_from(public_key: public_key, keydir: keydir)

      encryption_manager = EncryptionManager.new(plaindata, public_key, private_key)
      encryption_manager.encrypt
    end

    def encrypt_file_in_place(file_path, keydir: nil)
      plaindata = YAML.load_file(file_path)
      cipherdata = encrypt(plaindata, keydir: keydir)

      eyaml = format_for_file(cipherdata, file_path)

      File.write(file_path, eyaml)
      eyaml.bytesize
    end

    def decrypt(cipherdata, **key_options)
      public_key = load_public_key(cipherdata)
      private_key = load_private_key_from(public_key: public_key, **key_options)

      encryption_manager = EncryptionManager.new(cipherdata, public_key, private_key)
      encryption_manager.decrypt
    end

    def decrypt_file(file_path, **key_options)
      cipherdata = YAML.load_file(file_path)
      plaindata = decrypt(cipherdata, **key_options)
      format_for_file(plaindata, file_path)
    end

    private

    def load_public_key(data)
      raise EYAML::MissingPublicKey unless data.has_key?(INTERNAL_PUB_KEY)
      data.fetch(INTERNAL_PUB_KEY)
    end

    def load_private_key_from(public_key:, keydir: nil, private_key: nil)
      return private_key unless private_key.nil?
      File.read(File.expand_path(public_key, ensure_keydir(keydir)))
    end

    def ensure_keydir(keydir)
      keydir || ENV["EJSON_KEYDIR"] || DEFAULT_KEYDIR
    end

    def format_for_file(data, file_path)
      case File.extname(file_path)
      when ".eyaml", ".eyml"
        EYAML::Util.pretty_yaml(data)
      when ".ejson"
        JSON.pretty_generate(data)
      else
        raise EYAML::InvalidFormatError, "Unsupported file type"
      end
    end
  end
end

require_relative "eyaml/version"
require_relative "eyaml/util"
require_relative "eyaml/cli"
require_relative "eyaml/encryption_manager"
