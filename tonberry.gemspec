# frozen_string_literal: true

require_relative "lib/tonberry/version"

Gem::Specification.new do |spec|
  spec.name = "tonberry"
  spec.version = Tonberry::VERSION
  spec.authors = ["Yuji Yaginuma"]
  spec.email = ["yuuji.yaginuma@gmail.com"]

  spec.summary = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/y-yagi/tonberry"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bigdecimal"
  spec.add_dependency "anthropic"
  spec.add_dependency "base64"
  spec.add_dependency "ruby_llm"
  spec.add_dependency "rainbow"
  spec.add_dependency "reline"
  spec.add_dependency "tiktoken_ruby"
end
