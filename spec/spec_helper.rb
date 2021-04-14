# frozen_string_literal: true

require "bundler/setup"
require "pry"
require "fileutils"
require "fakefs/spec_helpers"

require "rails"
require "eyaml"

require_relative "support/encryption_helper"
require_relative "support/custom_matchers"
require_relative "support/path_helper"
require_relative "support/file_helper"
require_relative "support/rails_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Allow setting the focus on test case(s) when debugging
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(PathHelper)
end
