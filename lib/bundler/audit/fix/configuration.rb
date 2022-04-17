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

require 'yaml'
require 'bundler/audit/configuration'

module Bundler
  module Audit
    module Fix
      #
      # Class for configurations.
      #
      class Configuration < Configuration
        attr_accessor :replacements

        class << self
          def load(file_path)
            instance = super(file_path)

            doc = YAML.parse(File.new(file_path))
            doc.root.children.each_slice(2) do |key, value|
              case key.value
              when 'replacement'
                unless value.children.is_a?(Array)
                  raise(InvalidConfigurationError, "'replacement' key found in config file, but is not an Array")
                end

                instance.replacements ||= {}
                instance.replacements = instance.replacements.merge(build_replacements(value))
              end
            end

            instance
          end

          def build_replacements(params)
            params.children.each_slice(2).map do |key, value|
              unless value.children
                raise(InvalidConfigurationError,
                      "'replacement.#{key.value}' in config file is empty")
              end

              unless value.children.all? { |node| node.is_a?(YAML::Nodes::Scalar) }
                raise(InvalidConfigurationError,
                      "'replacement.#{key.value}' array in config file contains a non-String")
              end

              { key.value => value.children.map(&:value) }
            end.inject(&:merge)
          end
        end

        def initialize(config = {})
          super(config)
          load_default
        end

        private

        def load_default
          base_dir = File.realpath(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))
          default_config_path = File.join(base_dir, 'config', 'default.yml')
          doc = YAML.parse(File.new(default_config_path))
          doc.root.children.each_slice(2) do |key, value|
            case key.value
            when 'replacement'
              self.replacements = self.class.build_replacements(value)
            end
          end
        end
      end
    end
  end
end
