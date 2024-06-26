# frozen_string_literal: true

require_relative "lib/eyaml/version"

Gem::Specification.new do |spec|
  spec.name = "eyaml"
  spec.version = EYAML::VERSION
  spec.authors = ["Emil Stolarsky"]
  spec.email = ["emil@cheddar.me"]

  spec.summary = "Asymmetric keywise encryption for YAML"
  spec.description = "Secret management by encrypting values in a YAML file with a public/private keypair"
  spec.homepage = "https://github.com/cheddar-me/eyaml"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.1")

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "bin"
  spec.executables = "eyaml"
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.1"
  spec.add_dependency "rbnacl", "~> 7.1"

  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("debug")
end
