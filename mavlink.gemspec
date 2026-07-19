# frozen_string_literal: true

require_relative "lib/mavlink/version"

Gem::Specification.new do |spec|
  spec.name = "mavlink"
  spec.version = MAVLink::VERSION
  spec.authors = ["Thomas Smith"]
  spec.email = []

  spec.summary = "A compact, high-performance MAVLink protocol implementation for Ruby"
  spec.description = "A compact, high-performance implementation of the MAVLink protocol written in Ruby."
  spec.homepage = "https://github.com/thomassmithdev/mavlink-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.start_with?(*%w[bin/ test/ spec/ features/ .git .github])
    end
  end
  spec.require_paths = ["lib"]
end
