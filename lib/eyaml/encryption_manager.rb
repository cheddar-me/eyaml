module EYAML
  class UnsupportedVersionError < StandardError; end

  class EncryptionManager
    FORMAT_REGEX = /\AEJ\[(?<version>[^:]+):(?<session_public_key>[^:]+):(?<nonce>[^:]+):(?<text>[^\]]+)\]\z/
    FORMAT_VERSION = "1"

    class << self
      def new_keypair
        private_key = RbNaCl::PrivateKey.generate

        [
          RbNaCl::Util.bin2hex(private_key.public_key),
          RbNaCl::Util.bin2hex(private_key)
        ]
      end
    end

    def initialize(yaml, public_key, private_key = nil)
      @tree = yaml
      @public_key = RbNaCl::Util.hex2bin(public_key)
      @private_key = private_key && RbNaCl::Util.hex2bin(private_key.strip)
    end

    def decrypt
      traverse(@tree) do |text|
        encrypted?(text) ? decrypt_text(text) : text
      end
    end

    def encrypt
      traverse(@tree) do |text|
        encrypted?(text) ? text : encrypt_text(text)
      end
    end

    private

    def encrypt_text(plaintext)
      nonce = RbNaCl::Random.random_bytes(encryption_box.nonce_bytes)
      ciphertext = encryption_box.encrypt(nonce, plaintext)

      [
        "EJ[#{FORMAT_VERSION}",
        Base64.strict_encode64(session_public_key),
        Base64.strict_encode64(nonce),
        "#{Base64.strict_encode64(ciphertext)}]"
      ].join(":")
    end

    def decrypt_text(ciphertext)
      captures = ciphertext.match(FORMAT_REGEX).named_captures
      wire_version = captures.fetch("version")
      old_session_public_key = Base64.decode64(captures.fetch("session_public_key"))
      nonce = Base64.decode64(captures.fetch("nonce"))
      text = Base64.decode64(captures.fetch("text"))

      raise UnsupportedVersionError, "EYAML only supports version 1" unless wire_version == FORMAT_VERSION

      box = decryption_box(old_session_public_key)
      box.decrypt(nonce, text)
    end

    def encryption_box
      @encryption_box ||= RbNaCl::Box.new(@public_key, session_private_key)
    end

    def decryption_box(public_key_encrypted_with)
      @decryption_box ||= {}
      @decryption_box[public_key_encrypted_with] ||= RbNaCl::Box.new(public_key_encrypted_with, @private_key)
    end

    def session_private_key
      @session_private_key ||= RbNaCl::PrivateKey.generate
    end

    def session_public_key
      @session_public_key ||= session_private_key.public_key
    end

    def encrypted?(text)
      FORMAT_REGEX.match?(text)
    end

    def traverse(tree, &block)
      tree.map do |key, value|
        if value.is_a?(Hash)
          next [key, traverse(value, &block)]
        end
        if key.start_with?("_")
          next [key, value]
        end

        [key, block.call(value)]
      end.to_h
    end
  end
end
