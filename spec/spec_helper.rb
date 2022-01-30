# frozen_string_literal: true

require 'English'
require 'fileutils'
require 'rspec'
require 'bundler/audit/database'
require 'bundler/audit/fix'

# https://github.com/rubysec/bundler-audit/blob/f64883a878d172722164495668ff205c21eb55c3/spec/spec_helper.rb
module Fixtures
  ROOT    = File.expand_path('fixtures', __dir__)
  TMP_DIR = File.expand_path('tmp', __dir__)

  module Database
    PATH = File.join(ROOT, 'database')

    COMMIT = '892001c5257a7e1c930155b5dc8a5c8df6a071db'

    def self.clone
      system 'git', 'clone', '--quiet', Bundler::Audit::Database::URL, PATH
    end

    def self.reset!(commit = COMMIT)
      Dir.chdir(PATH) do
        system 'git', 'reset', '--hard', commit
      end
    end
  end

  def self.join(*paths)
    File.join(ROOT, *paths)
  end
end

module Helpers
  def sh(command, options = {})
    result = `#{command} 2>&1`

    raise "FAILED #{command}\n#{result}" if $CHILD_STATUS.success? == !options[:fail].nil?

    result
  end

  def decolorize(string)
    string.gsub(/\e\[\d+m/, '')
  end
end

RSpec.configure do |config|
  include Helpers
  include Bundler::Audit

  config.before(:suite) do
    Fixtures::Database.clone unless File.directory?(Fixtures::Database::PATH)

    Fixtures::Database.reset!

    FileUtils.mkdir_p(Fixtures::TMP_DIR)
  end

  config.before(:each) do
    stub_const('Bundler::Audit::Database::DEFAULT_PATH', Fixtures::Database::PATH)
    %w[Gemfile Gemfile.lock].each do |f|
      FileUtils.copy_file(File.join(directory, f), File.join(directory, "#{f}.bak"))
    end
  end

  config.after(:each) do
    %w[Gemfile Gemfile.lock].each do |f|
      FileUtils.move(File.join(directory, "#{f}.bak"), File.join(directory, f))
    end
  end
end
