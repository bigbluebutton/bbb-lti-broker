# frozen_string_literal: true

require_relative 'task_helpers'

namespace :db do
  namespace :registration do
    desc 'Add new Tool configuration [issuer,client_id,keyset_url,auth_token_url,auth_login_url,tenant_uid] (URLs should be enclosed by quotes)'
    task :new, %i[issuer client_id key_set_url auth_token_url auth_login_url tenant_uid] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      # Issuer or Platform ID.
      issuer = args[:issuer]
      if issuer.blank?
        $stdout.puts('What is the Issuer or Platform ID?')
        issuer = $stdin.gets.strip
      end
      abort('The Issuer must be valid.') if issuer.blank?

      # Client ID.
      client_id = args[:client_id]
      if client_id.blank?
        $stdout.puts('What is the Client ID?')
        client_id = $stdin.gets.strip
      end
      abort('The Client ID must be valid.') if client_id.blank?

      # Public Keyset URL.
      key_set_url = args[:key_set_url]
      if key_set_url.blank?
        $stdout.puts('What is the Public Keyset URL?')
        key_set_url = $stdin.gets.strip
      end
      abort('The Keyset URL must be valid.') if key_set_url.blank?

      # Access Token URL.
      auth_token_url = args[:auth_token_url]
      if auth_token_url.blank?
        $stdout.puts('What is the Access Token URL?')
        auth_token_url = $stdin.gets.strip
      end
      abort('The Access Token URL must be valid.') if auth_token_url.blank?

      # Authentication Request Login URL.
      auth_login_url = args[:auth_login_url]
      if auth_login_url.blank?
        $stdout.puts('What is the Authentication Request Login URL?')
        auth_login_url = $stdin.gets.strip
      end
      abort('The Authentication Request Login URL must be valid.') if auth_login_url.blank?

      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      key_dir = Digest::MD5.hexdigest(issuer + client_id)
      Dir.mkdir('.ssh/') unless Dir.exist?('.ssh/')
      Dir.mkdir(".ssh/#{key_dir}") unless Dir.exist?(".ssh/#{key_dir}")

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
        tool_private_key: Rails.root.join(".ssh/#{key_dir}/priv_key"),
      }

      tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant_uid]) if args[:tenant_uid].present?
      tenant = RailsLti2Provider::Tenant.first if tenant.nil?
      abort('Tenant not found. Tenant UID must be valid or Deafult Tenant must exist.') if tenant.nil?

      abort("Issuer or Platform ID has already been registered for tenant '#{tenant.uid}'.") if RailsLti2Provider::Tool.exists?(uuid: issuer, tenant: tenant)

      tool = RailsLti2Provider::Tool.create(
        uuid: issuer,
        shared_secret: client_id,
        tool_settings: reg.to_json,
        lti_version: '1.3.0',
        tenant: tenant
      )

      $stdout.puts("Tool:\n#{tool.to_json}")
      $stdout.puts("\n")
      $stdout.puts("Private Key:\n#{private_key}")
      $stdout.puts("\n")
      $stdout.puts("Public Key:\n#{public_key}")
      $stdout.puts("\n")
      $stdout.puts("JWK:\n#{jwk}")
      $stdout.puts("\n")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Delete existing Tool configuration'
    task :delete, [] => :environment do |_t, _args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      $stdout.puts('What is the issuer for the registration you wish to delete?')
      issuer = $stdin.gets.strip
      $stdout.puts('What is the client ID for the registration?')
      client_id = $stdin.gets.strip

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
    task :keygen, [:type] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      abort('Type must be one of [key, jwk]') unless %w[key jwk].include?(args[:type])

      $stdout.puts('What is the issuer for the registration?')
      issuer = $stdin.gets.strip
      $stdout.puts('What is the client ID for the registration?')
      client_id = $stdin.gets.strip

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
      Dir.mkdir(".ssh/#{key_dir}") unless Dir.exist?(".ssh/#{key_dir}")

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
      puts(public_key) if args[:type] == 'key'
    end

    desc 'Lists the Registration Configuration URLs need to register an app [app]'
    task :url, [:app] => :environment do |_t, args|
      include Rails.application.routes.url_helpers
      default_url_options[:host] = ENV['URL_HOST']

      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      app_name = args[:app] || Rails.configuration.default_tool
      app = Doorkeeper::Application.find_by(name: app_name)
      if app.nil?
        puts("App '#{app_name}' does not exist, no urls can be given.")
        exit(1)
      end

      # Setting temp keys
      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key

      # keep temp files in scope so they are not deleted
      storage = TemporaryStorage.new
      public_key_file = storage.store('bbb-lti-rsa-pub-', public_key.to_s)
      private_key_file = storage.store('bbb-lti-rsa-pri-', private_key.to_s)

      temp_key_token = SecureRandom.hex

      ActiveRecord::Base.connection.cache do
        Rails.cache.write(temp_key_token, public_key_path: public_key_file.path, private_key_path: private_key_file.path, timestamp: Time.now.to_i)
      end

      # Setting jwk with same private key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      $stdout.puts("Tool URL:\n#{openid_launch_url(protocol: 'https', app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Deep Link URL:\n#{deep_link_request_launch_url(protocol: 'https', app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Initiate login URL:\n#{openid_login_url(protocol: 'https', app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts(format("Redirection URI(s):\n#{openid_launch_url(protocol: 'https', app: app.name)}\n#{deep_link_request_launch_url(protocol: 'https', app: app.name)}"))
      $stdout.puts("\n")
      $stdout.puts("Private Key:\n#{private_key}")
      $stdout.puts("\n")
      $stdout.puts("Public Key:\n#{public_key}")
      $stdout.puts("\n")
      $stdout.puts("JWK:\n#{jwk}")
      $stdout.puts("\n")
      $stdout.puts("JSON Configuration URL:\n#{json_config_url(protocol: 'https', app: app.name, temp_key_token: temp_key_token)}")
    end

    desc 'Deletes the registration keys inside the temporary bbb-lti folder'
    task :clear_tmp, [] => :environment do |_t|
      storage = TemporaryStorage.new

      # Removes everything inside the bbb-lti folder
      FileUtils.rm_rf(Dir["#{storage.temp_folder}/*"])
    end

    namespace :enable do
      desc 'Enable a registration by [key,value]'
      task :by, [:key, :value] => :environment do |_t, args|
        $stdout.puts("db:registration:enable:by[#{args[:key]},#{args[:value]}]")

        # Key.
        key = args[:key]
        if key.blank?
          $stdout.puts('What is the Key?')
          key = $stdin.gets.strip
        end
        abort('The Key cannot be blank.') if key.blank?

        # Value.
        value = args[:value]
        if value.blank?
          $stdout.puts('What is the Value?')
          value = $stdin.gets.strip
        end
        abort('The Value cannot be blank.') if value.blank?

        TaskHelpers.tool_enable_by(key.to_sym, value)
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Enable all registrations'
      task all: :environment do |_t|
        $stdout.puts('db:registration:enable:all')

        registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
        registrations.each do |registration|
          TaskHelpers.tool_enable_by(:id, registration.id)
        end
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end
    end

    desc 'Enable a registration by ID [id]'
    task :enable, [:id] => :environment do |_t, args|
      $stdout.puts("db:registration:enable[#{args[:id]}]")

      # ID.
      id = args[:id]
      if id.blank?
        $stdout.puts('What is the ID?')
        id = $stdin.gets.strip
      end
      abort('The ID must be valid.') if id.blank?

      TaskHelpers.tool_enable_by(:id, id)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    namespace :disable do
      desc 'Disable a registration by [key,value]'
      task :by, [:key, :value] => :environment do |_t, args|
        $stdout.puts("db:registration:disable:by[#{args[:key]},#{args[:value]}]")

        # Key.
        key = args[:key]
        if key.blank?
          $stdout.puts('What is the Key?')
          key = $stdin.gets.strip
        end
        abort('The Key cannot be blank.') if key.blank?

        # Value.
        value = args[:value]
        if value.blank?
          $stdout.puts('What is the Value?')
          value = $stdin.gets.strip
        end
        abort('The Value cannot be blank.') if value.blank?

        TaskHelpers.tool_disable_by(key.to_sym, value)
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Disable all registrations'
      task all: :environment do |_t|
        $stdout.puts('db:registration:disable:all')

        registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
        registrations.each do |registration|
          TaskHelpers.tool_disable_by(:id, registration.id)
        end
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end
    end

    desc 'Disable a registration by ID [id]'
    task :disable, [:id] => :environment do |_t, args|
      $stdout.puts("db:registration:disable[#{args[:id]}]")

      # ID.
      id = args[:id]
      if id.blank?
        $stdout.puts('What is the ID?')
        id = $stdin.gets.strip
      end
      abort('The ID must be valid.') if id.blank?

      TaskHelpers.tool_disable_by(:id, id)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Show all existent registrations'
  task :registration, [] => :environment do |_t|
    include BbbLtiBroker::Helpers
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
    registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
    registrations.each do |registration|
      output = "{'id': '#{registration.id}', 'uuid': '#{registration.uuid}', 'shared_secret': '#{registration.shared_secret}'}"
      output += " for tenant '#{registration.tenant.uid}'" unless registration.tenant.uid.empty?
      output += " is #{registration.status}"
      puts(output)
    end
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end
end
