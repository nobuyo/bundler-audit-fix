# Bundler::Audit::Fix

Automatically apply patched version of gems audited by [rubysec/bunder-audit](https://github.com/rubysec/bundler-audit).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bundler-audit-fix'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bundler-audit-fix

## Usage

```sh
$ bundle-audit-fix update [dir]
```

### .bundler-audit.yml

In addition to the original configuration, it supports `replacement` block.  If a gem that is related to a fixed version and not directly listed in the Gemfile (i.g. Rails family, etc.) needs to be updated, bundle-audit-fix will replace according to the specified like below.

```yml
replacement:
  rails:
    - actionpack
    - actionview
    - activemodel
    - activerecord
    - actionmailer
    - activejob
    - actioncable
    - activestorage
    - activesupport
    - actionmailbox
    - actiontext
    - railties
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nobuyo/bundler-audit-fix.

## License

Copyright (c) 2021 Nobuo Takizawa

bundler-audit-fix is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

bundler-audit-fix is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with bundler-audit-fix.  If not, see <https://www.gnu.org/licenses/>.
