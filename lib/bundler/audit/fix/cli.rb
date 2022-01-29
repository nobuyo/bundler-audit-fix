# frozen_string_literal: true

#
# Copyright (c) 2021 Nobuo Takizawa
#
# bundler-audit-fix is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# bundler-audit-fix is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bundler-audit-fix.  If not, see <https://www.gnu.org/licenses/>.
#

require 'thor'
require 'bundler'
require 'bundler/cli'
require 'bundler/cli/update'
require 'bundler/audit/cli'
require 'bundler/audit/database'
require 'fileutils'

module Bundler
  module Audit
    module Fix
      #
      # The `bundle-audit-fix` command.
      #
      class CLI < ::Thor
        include Thor::Actions

        default_task :update
        map '--version' => :version

        desc 'check [DIR]', 'Checks the Gemfile.lock for insecure dependencies'
        method_option :ignore,       type: :array,   aliases: '-i'
        method_option :update,       type: :boolean, aliases: '-u'
        method_option :database,     type: :string,  aliases: '-D', default: Database::USER_PATH
        method_option :config,       type: :string,  aliases: '-c', default: '.bundler-audit.yml'
        method_option :gemfile_lock, type: :string,  aliases: '-G', default: 'Gemfile.lock'

        def update(dir = Dir.pwd)
          unless File.directory?(dir)
            say_error "No such file or directory: #{dir}", :red
            exit 1
          end

          if !Database.exists?(options[:database])
            Bundler::Audit::CLI.new.invoke(:download, options[:database])
          elsif options[:update]
            Bundler::Audit::CLI.new.invoke(:update, options[:database])
          end

          gemfile      = options[:gemfile_lock].sub(/\.lock$/, '')
          gemfile_path = File.join(dir, gemfile)

          # for https://github.com/rubygems/bundler/blob/35be6d9a603084f719fec4f4028c18860def07f6/lib/bundler/shared_helpers.rb#L229
          ENV['BUNDLE_GEMFILE'] = gemfile_path

          database = Database.new(options[:database])
          begin
            scanner = Scanner.new(dir, options[:gemfile_lock], database, options[:config])
            scanner.scan

            report = scanner.report(ignore: options.ignore)
            unless report.vulnerable?
              say 'Nothing to do, exiting.', :green
              exit 0
            end

            patcher = Patcher.new(dir, report, options[:gemfile_lock], options[:config])
            gems_to_update = patcher.patch

            current_lockfile = StringIO.new(File.read(options[:gemfile_lock]))
            Bundler::CLI::Update.new({ gemfile: gemfile_path }, gems_to_update).run
            updated_lockfile = StringIO.new(File.read(options[:gemfile_lock]))

            if FileUtils.compare_stream(current_lockfile, updated_lockfile)
              say 'All of the targets are staying in the same version for dependency reasons. Please resolve them manually.',
                  :yellow
              exit 1
            end

            exit 0
          rescue Bundler::GemfileNotFound, Bundler::GemfileLockNotFound => e
            say e.message, :red
            exit 1
          end
        end

        desc 'version', 'Prints the bundler-audit-fix version'
        def version
          puts Fix::VERSION
        end
      end
    end
  end
end
