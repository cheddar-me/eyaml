# frozen_string_literal: true

require "pry"
require "fileutils"
require "fakefs/spec_helpers"

require "encryption_spec_helpers"
require "custom_matchers"

require "eyaml"

FIXTURES_PATH = File.expand_path("../fixtures", __FILE__)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # https://relishapp.com/rspec/rspec-core/docs/example-groups/shared-context#background
  # rspec.shared_context_metadata_behavior = :apply_to_host_groups

  # Allow setting the focus on test case(s) when debugging
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
