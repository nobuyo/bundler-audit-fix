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
require 'bundler/audit/cli'
require 'bundler/audit/database'

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
        method_option :ignore,       type: :array,  aliases: '-i'
        method_option :database,     type: :string, aliases: '-D', default: Database::USER_PATH
        method_option :config,       type: :string, aliases: '-c', default: '.bundler-audit.yml'
        method_option :gemfile_lock, type: :string, aliases: '-G', default: 'Gemfile.lock'

        def update(dir = Dir.pwd)
          unless File.directory?(dir)
            say_error "No such file or directory: #{dir}", :red
            exit 1
          end

          unless Database.exists?(options[:database])
            say_error 'No database is found', :red
            exit 1
          end

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

            gemfile      = options[:gemfile_lock].sub(/\.lock$/, '')
            gemfile_path = File.join(dir, gemfile)

            run "bundle update #{gems_to_update.join(" ")} --gemfile=#{gemfile_path}"
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
