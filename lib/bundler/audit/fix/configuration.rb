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

        def self.load(file_path)
          instance = super(file_path)

          doc = YAML.parse(File.new(file_path))
          doc.root.children.each_slice(2) do |key, value|
            case key.value
            when 'replacement'
              unless value.children.is_a?(Array)
                raise(InvalidConfigurationError, "'replacement' key found in config file, but is not an Array")
              end

              instance.replacements = build_replacements(value)
            end
          end

          instance
        end

        def self.build_replacements(params)
          params.children.each_slice(2).map do |key, value|
            raise(InvalidConfigurationError, "'replacement.#{key.value}' in config file is empty") unless value.children

            unless value.children.all? { |node| node.is_a?(YAML::Nodes::Scalar) }
              raise(InvalidConfigurationError, "'replacement.#{key.value}' array in config file contains a non-String")
            end

            { key.value => value.children.map(&:value) }
          end.inject(&:merge)
        end
      end
    end
  end
end
