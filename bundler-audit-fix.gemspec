# frozen_string_literal: true

require_relative 'lib/bundler/audit/fix/version'

Gem::Specification.new do |spec|
  spec.name          = 'bundler-audit-fix'
  spec.version       = Bundler::Audit::Fix::VERSION
  spec.authors       = ['Nobuo Takizawa']
  spec.email         = ['longzechangsheng@gmail.com']

  spec.summary       = 'Automatic apply security update inspected by bundler-audit.'
  spec.homepage      = 'https://github.com/nobuyo/bundler-audit-fix'
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/nobuyo/bundler-audit-fix'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{\Abin/bundler}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bundler', '>= 1.2.0', '< 3'
  spec.add_dependency 'bundler-audit', '~> 0.9.0'
  spec.add_dependency 'thor', '~> 1.0'
end
