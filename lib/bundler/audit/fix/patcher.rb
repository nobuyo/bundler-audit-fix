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

require 'bundler'
require 'bundler/audit'

module Bundler
  module Audit
    module Fix
      #
      # Patcher is a class for updating gem version specifications in Gemfile.
      #
      class Patcher
        attr_reader :config, :bundled_gems, :locked_gems, :gemfile_path, :lockfile_path, :report

        # @param [String] root
        #   The path to the project root.
        #
        # @param [Hash] report
        #   Result of ::Bundler::Audit::Scanner#report.
        #
        # @param [String] gemfile_lock
        #   Path to Gemfile.lock.
        #
        # @param [String] config_file_path
        #   Path to bundler-audit config file.
        def initialize(root, report, gemfile_lock = 'Gemfile.lock', config_file_path = '.bundler-audit.yml')
          root           = File.expand_path(root)
          gemfile        = gemfile_lock.sub(/\.lock$/, '')
          @gemfile_path  = File.join(root, gemfile)
          @lockfile_path = File.join(root, gemfile_lock)
          @report        = report

          unless File.file?(@gemfile_path)
            raise(Bundler::GemfileNotFound, "Could not find #{gemfile.inspect} in #{root.inspect}")
          end

          unless File.file?(@lockfile_path)
            raise(Bundler::GemfileLockNotFound, "Could not find #{gemfile_lock.inspect} in #{root.inspect}")
          end

          @bundled_gems = Bundler::Definition.build(@gemfile_path, nil, nil).dependencies
          @locked_gems = Bundler::LockfileParser.new(Bundler.read_file(@lockfile_path)).specs

          config_file_abs_path = File.absolute_path(config_file_path, root)
          @config = if File.exist?(config_file_abs_path)
                      Configuration.load(config_file_abs_path)
                    else
                      Configuration.new
                    end
        end

        #
        # Write patched versions to Gemfile and return gems list to update.
        #
        def patch
          patterns, gems_to_update = build_patterns
          gemfile = File.read(gemfile_path, encoding: 'utf-8')

          patterns.each do |pattern, replace_with|
            gemfile = gemfile.gsub(pattern, replace_with)
          end

          File.write(gemfile_path, gemfile)

          gems_to_update
        end

        private

        def build_patterns
          gems_to_update = []
          patterns = report.results.map do |r|
            name = replace_name_if_defined(name: r.gem.name)

            current = bundled_gems.find { |gem| gem.name == name }
            locked = locked_gems.find { |gem| gem.name == name }

            gems_to_update << name

            # If current does not exist here, skip it because the package is an indirect dependency.
            next if !current && locked

            patched_versions = r.advisory.patched_versions.map do |patched_version|
              Gem::Requirement.parse(patched_version.as_list[-1])[1]
            end

            new_requirement = patched_versions.find do |patched_version|
              patched_version > locked.version
            end

            current_requirement          = current.requirements_list.join("', '")
            current_requirement_operator = Gem::Requirement.parse(current.requirements_list[0])[0]

            if current_requirement_operator == '='
              current_requirement = Gem::Requirement.parse(current.requirements_list[0])[1]
            else
              new_requirement = "#{current_requirement_operator} #{new_requirement}"
            end

            [
              /gem '#{name}',\s*'#{current_requirement}'/,
              "gem '#{name}', '#{new_requirement}'"
            ]
          end.compact

          [patterns, gems_to_update]
        end

        def replace_name_if_defined(name:)
          return name unless config.replacements

          replacement = config.replacements.find do |_with, targets|
            targets.include?(name)
          end

          return name unless replacement

          replacement[0]
        end
      end
    end
  end
end
