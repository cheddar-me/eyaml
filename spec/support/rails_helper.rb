# frozen_string_literal: true

module RailsHelper
  def allow_rails
    allow(Rails)
  end

  def secrets_class
    ActiveSupport::OrderedOptions
  end

  def run_load_hooks
    ActiveSupport.run_load_hooks(:before_configuration)
  end

  def hide_secrets_files(*files)
    allow(EYAML::Rails::Railtie).to(receive(:valid?).and_call_original)
    files.each do |file|
      allow(EYAML::Rails::Railtie).to(receive(:valid?).with(file).and_return(false))
    end
  end

  def config_root
    fixtures_root.join("config")
  end

  def remove_secrets_files
    supported_extensions.each do |ext|
      File.delete(config_root.join("secrets.#{ext}"))
    end
  end

  def remove_environment_secrets_files
    supported_extensions.each do |ext|
      File.delete(config_root.join("secrets.env.#{ext}"))
    end
  end

  def remove_all_secrets_that_dont_end_with(ext)
    Dir[config_root.join("*")].each do |secret_path|
      next if secret_path.end_with?(ext)
      File.delete(secret_path)
    end
  end
end
