# frozen_string_literal: true

namespace :db do
  namespace :registration do
    desc 'Add new Tool configuration [key, jwk]'
    task :new, [:type] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      abort('Type must be one of [key, jwk]') unless %w[key jwk].include?(args[:type])

      $stdout.puts('What is the issuer?')
      issuer = $stdin.gets.strip

      abort('The issuer must be valid.') if issuer.blank?

      $stdout.puts('What is the client id?')
      client_id = $stdin.gets.strip

      $stdout.puts('What is the key set url?')
      key_set_url = $stdin.gets.strip

      $stdout.puts('What is the auth token url?')
      auth_token_url = $stdin.gets.strip

      $stdout.puts('What is the auth login url?')
      auth_login_url = $stdin.gets.strip

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
      puts(public_key) if args[:type] == 'key'
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

    desc 'Lists the Registration Configuration URLs need to register an app'
    task :url, [] => :environment do |_t|
      include Rails.application.routes.url_helpers
      default_url_options[:host] = ENV['URL_HOST']

      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      $stdout.puts('What is the app you want to register with?')
      requested_app = $stdin.gets.strip
      app = Doorkeeper::Application.find_by(name: requested_app)
      if app.nil?
        puts("App '#{requested_app}' does not exist, no urls can be given.")
        exit(1)
      end

      # Setting temp keys
      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key

      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      # keep temp files in scope so they are not deleted
      storage = TemporaryStorage.new
      public_key_file = storage.store('bbb-lti-rsa-pub-', public_key.to_s)
      private_key_file = storage.store('bbb-lti-rsa-pri-', private_key.to_s)

      temp_key_token = SecureRandom.hex

      ActiveRecord::Base.connection.cache do
        Rails.cache.write(temp_key_token, public_key_path: public_key_file.path, private_key_path: private_key_file.path, timestamp: Time.now.to_i)
      end

      $stdout.puts("Tool URL: \n#{openid_launch_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Deep Link URL: \n#{deep_link_request_launch_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Initiate login URL URL: \n#{openid_login_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts(format("Redirection URL(s):, \n#{openid_launch_url(app: app.name)}", "\n", deep_link_request_launch_url(app: app.name).to_s))
      $stdout.puts("\n")
      $stdout.puts("Public Key: \n #{public_key}")
      $stdout.puts("\n")
      $stdout.puts("JWK: \n #{jwk}")
      $stdout.puts("\n")
      $stdout.puts("JSON Configuration URL: \n #{json_config_url(app: app.name, temp_key_token: temp_key_token)}")
    end

    desc 'Deletes the registration keys inside the temporary bbb-lti folder'
    task :clear_tmp, [] => :environment do |_t|
      storage = TemporaryStorage.new

      # Removes everything inside the bbb-lti folder
      FileUtils.rm_rf(Dir["#{storage.temp_folder}/*"])
    end
  end
end
