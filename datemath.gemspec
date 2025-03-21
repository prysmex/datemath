# frozen_string_literal: true

require_relative 'lib/datemath/version'

Gem::Specification.new do |spec|
  spec.name          = 'datemath'
  spec.version       = Datemath::VERSION
  spec.authors       = ['victor-aguilars']
  spec.email         = ['victor.aguilarsnz@gmail.com']

  spec.summary       = "Elastic's datemath parser for Ruby"
  spec.description   = "Elastic's datemath parser for Ruby"
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4.2'

  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = spec.homepage
  # spec.metadata['changelog_uri'] = 'https://github.com/apartmentlist/sidekiq-bouncer/blob/master/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 7.2'
end
