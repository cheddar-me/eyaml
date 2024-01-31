# frozen_string_literal: true

module EYAML
  module Rails
    Rails = ::Rails
    private_constant :Rails

    class Railtie < Rails::Railtie
      PRIVATE_KEY_ENV_VAR = "EJSON_PRIVATE_KEY"

      config.before_configuration do
        secrets_or_credentials = if Rails.version >= "7.2" || Dir.glob(Rails.root.join("config", "credentials.*")).any?
          :credentials
        else
          :secrets
        end

        secrets_files(secrets_or_credentials).each do |file|
          next unless valid?(file)

          # If private_key is nil (i.e. when $EJSON_PRIVATE_KEY is not set), EYAML will search
          # for a public/private key in the key directory (either $EJSON_KEYDIR, if set, or /opt/ejson/keys)
          cipherdata = YAML.load_file(file)
          secrets = EYAML.decrypt(cipherdata, private_key: ENV[PRIVATE_KEY_ENV_VAR])
            .deep_symbolize_keys
            .except(:_public_key)

          break Rails.application.send(secrets_or_credentials).deep_merge!(secrets)
        end
      end

      class << self
        private

        def valid?(pathname)
          pathname.exist?
        end

        def secrets_files(secrets_or_credentials)
          EYAML::SUPPORTED_EXTENSIONS.map do |ext|
            [
              Rails.root.join("config", "#{secrets_or_credentials}.#{ext}"),
              Rails.root.join("config", "#{secrets_or_credentials}.#{Rails.env}.#{ext}")
            ]
          end.flatten
        end
      end
    end
  end
end
