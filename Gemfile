# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in eyaml.gemspec
gemspec

gem "ffi", github: "cheddar-me/ffi", branch: "apple-m1", submodules: true
gem "rbnacl", github: "cheddar-me/rbnacl", branch: "apple-m1", submodules: true

group :development, :test do
  gem "pry"
end
