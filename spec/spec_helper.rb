# frozen_string_literal: true

require "pry"
require "fileutils"
require "fakefs/spec_helpers"

require "support/encryption_helper"
require "support/custom_matchers"
require "support/path_helper"
require "support/file_helper"
require "support/rails_helper"

require "rails"
require "eyaml"

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
