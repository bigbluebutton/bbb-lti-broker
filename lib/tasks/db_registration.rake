# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

namespace :db do
  namespace :registration do
    desc 'Add new Tool configuration [key, jwk]'
    task :new, [:type] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      abort('Type must be one of [key, jwk]') unless %w[key jwk].include?(args[:type])

      STDOUT.puts('What is the issuer?')
      issuer = STDIN.gets.strip

      abort('The issuer must be valid.') if issuer.blank?

      STDOUT.puts('What is the client id?')
      client_id = STDIN.gets.strip

      STDOUT.puts('What is the key set url?')
      key_set_url = STDIN.gets.strip

      STDOUT.puts('What is the auth token url?')
      auth_token_url = STDIN.gets.strip

      STDOUT.puts('What is the auth login url?')
      auth_login_url = STDIN.gets.strip

      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      key_dir = Digest::MD5.hexdigest(issuer + client_id)
      Dir.mkdir('.ssh/') unless Dir.exist?('.ssh/')
      Dir.mkdir('.ssh/' + key_dir) unless Dir.exist?('.ssh/' + key_dir)

      File.open(Rails.root.join(".ssh/#{key_dir}/priv_key"), 'w') do |f|
        f.puts(private_key.to_s)
      end

      File.open(Rails.root.join(".ssh/#{key_dir}/pub_key"), 'w') do |f|
        f.puts(public_key.to_s)
      end

      reg = {
        issuer: issuer,
        client_id: client_id,
        key_set_url: key_set_url,
        auth_token_url: auth_token_url,
        auth_login_url: auth_login_url,
        # tool_private_key: "#{Rails.root}/.ssh/#{key_dir}/priv_key",
        tool_private_key: Rails.root.join(".ssh/#{key_dir}/priv_key"), # #{Rails.root}/.ssh/#{key_dir}/priv_key",
      }

      RailsLti2Provider::Tool.create(
        uuid: issuer,
        shared_secret: client_id,
        tool_settings: reg.to_json,
        lti_version: '1.3.0'
      )

      puts(jwk) if args[:type] == 'jwk'
      puts(public_key.to_s) if args[:type] == 'key'
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Delete existing Tool configuration'
    task :delete, [] => :environment do |_t, _args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      STDOUT.puts('What is the issuer for the registration you wish to delete?')
      issuer = STDIN.gets.strip
      STDOUT.puts('What is the client ID for the registration?')
      client_id = STDIN.gets.strip

      options = {}
      options['client_id'] = client_id if client_id.present?

      reg = RailsLti2Provider::Tool.find_by_issuer(issuer, options)

      if JSON.parse(reg.tool_settings)['tool_private_key'].present?
        key_dir = Pathname.new(JSON.parse(reg.tool_settings)['tool_private_key']).parent.to_s
        FileUtils.remove_dir(key_dir, true) if Dir.exist?(key_dir)
      end

      reg.destroy
    end

    desc 'Generate new key pair for existing Tool configuration [key, jwk]'
    task :keygen, [:type] => :environment do |_t, _args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      abort('Type must be one of [key, jwk]') unless %w[key jwk].include?(args[:type])

      STDOUT.puts('What is the issuer for the registration?')
      issuer = STDIN.gets.strip
      STDOUT.puts('What is the client ID for the registration?')
      client_id = STDIN.gets.strip

      options = {}
      options['client_id'] = client_id if client_id.present?
      registration = RailsLti2Provider::Tool.find_by_issuer(issuer, options)

      abort('The registration must be valid.') if registration.blank?

      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      key_dir = Digest::MD5.hexdigest(issuer + client_id)
      Dir.mkdir('.ssh/') unless Dir.exist?('.ssh/')
      Dir.mkdir('.ssh/' + key_dir) unless Dir.exist?('.ssh/' + key_dir)

      # File.open(File.join(Rails.root, '.ssh', key_dir, 'priv_key'), 'w') do |f|
      #   f.puts(private_key.to_s)
      # end
      File.open(Rails.root.join(".ssh/#{key_dir}/priv_key"), 'w') do |f|
        f.puts(private_key.to_s)
      end

      # File.open(File.join(Rails.root, '.ssh', key_dir, 'pub_key'), 'w') do |f|
      #   f.puts(public_key.to_s)
      # end
      File.open(Rails.root.join(".ssh/#{key_dir}/pub_key"), 'w') do |f|
        f.puts(public_key.to_s)
      end

      tool_settings = JSON.parse(registration.tool_settings)
      tool_settings['tool_private_key'] = Rails.root.join(".ssh/#{key_dir}/priv_key") # "#{Rails.root}/.ssh/#{key_dir}/priv_key"
      registration.update(tool_settings: tool_settings.to_json, shared_secret: client_id)

      puts(jwk) if args[:type] == 'jwk'
      puts(public_key.to_s) if args[:type] == 'key'
    end
  end
end
