# frozen_string_literal: true

module EYAML
  module Rails
    Rails = ::Rails
    private_constant :Rails

    class Railtie < Rails::Railtie
      PRIVATE_KEY_ENV_VAR = "EJSON_PRIVATE_KEY"

      class ConflictError < StandardError
      end

      config.before_configuration do
        if File.exist?(Rails.root.join("config", "master.key"))
          raise ConflictError, "A config/master.key has been found. The rails credentials lookup conflicts with eyaml. Please remove rails credentials management by removing the master.key file to keep using eyaml."
        end
        secret_files_present = Dir.glob(auth_files(:secrets)).any?
        credential_files_present = Dir.glob(auth_files(:credentials)).any?

        secrets_or_credentials = if Rails.version >= "7.2"
          :credentials
        else
          if credential_files_present
            :credentials
          elsif secret_files_present
            :secrets
          end
        end

        auth_files(secrets_or_credentials).each do |file|
          next unless valid?(file)

          # If private_key is nil (i.e. when $EJSON_PRIVATE_KEY is not set), EYAML will search
          # for a public/private key in the key directory (either $EJSON_KEYDIR, if set, or /opt/ejson/keys)
          cipherdata = YAML.load_file(file)
          secrets = EYAML.decrypt(cipherdata, private_key: ENV[PRIVATE_KEY_ENV_VAR])
            .except("_public_key")
          secrets = EYAML::Util.with_deep_deundescored_keys(secrets)
            .deep_symbolize_keys

          break Rails.application.send(secrets_or_credentials).deep_merge!(secrets)
        end
      end

      class << self
        private

        def valid?(pathname)
          pathname.exist?
        end

        def auth_files(secrets_or_credentials)
          EYAML::SUPPORTED_EXTENSIONS.flat_map do |ext|
            [
              Rails.root.join("config", "#{secrets_or_credentials}.#{ext}"),
              Rails.root.join("config", "#{secrets_or_credentials}.#{Rails.env}.#{ext}")
            ]
          end
        end
      end
    end
  end
end
