# frozen_string_literal: true

require_relative 'task_helpers'

namespace :tool do
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ENV['URL_HOST']

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

    # Validate the tenant as it is a point of failure and if not valid, there is no point on continuing.
    tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant_uid]) if args[:tenant_uid].present?
    tenant = RailsLti2Provider::Tenant.first if tenant.nil?
    abort('Tenant not found. Tenant UID must be valid or Deafult Tenant must exist.') if tenant.nil?
    abort("Issuer or Platform ID has already been registered for tenant '#{tenant.uid}'.") if RailsLti2Provider::Tool.exists?(uuid: issuer, tenant: tenant)

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
    key_pair_token = Digest::MD5.hexdigest(SecureRandom.uuid)

    rsa_key_pair = RsaKeyPair.create(
      private_key: private_key.to_s,
      public_key: public_key.to_s,
      token: key_pair_token
    )

    tool_settings = {
      issuer: issuer,
      client_id: client_id,
      key_set_url: key_set_url,
      auth_token_url: auth_token_url,
      auth_login_url: auth_login_url,
      rsa_key_pair_id: rsa_key_pair.id,
      rsa_key_pair_token: rsa_key_pair.token,
    }

    tool = RailsLti2Provider::Tool.create(
      uuid: issuer,
      shared_secret: client_id,
      tool_settings: tool_settings.to_json,
      lti_version: '1.3.0',
      tenant: tenant
    )

    $stdout.puts("Tool:\n#{tool.to_json}")
    $stdout.puts("\n")
    $stdout.puts("Private Key:\n#{private_key}")
    $stdout.puts("\n")
    $stdout.puts("Public Key:\n#{public_key}")
    $stdout.puts("\n")
    $stdout.puts("Public Key URL:\n#{registration_pub_keyset_url(protocol: 'https', key_token: key_pair_token)}")
    $stdout.puts("\n")
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  namespace :show do
    desc 'Show a tool by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts('tool:show:by[key,value]')

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

      tool = RailsLti2Provider::Tool.find_by(lti_version: '1.3.0', key.to_sym => value)
      abort("The tool with #{key} = #{value} does not exist") if tool.blank?

      Rake::Task['tool:show'].invoke(tool.id)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Show all tools'
    task all: :environment do |_t|
      $stdout.puts('tool:show:all')

      tools = RailsLti2Provider::Tool.select(:id, :uuid, :shared_secret, :status, :tenant_id).where(lti_version: '1.3.0')
      tools.each do |tool|
        puts(tool.to_json)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Show tools, by ID [id] if provided or all if it is not.'
  task :show, [:id] => :environment do |_t, args|
    # ID. Default to all if blank.
    id = args[:id]
    if id.blank?
      Rake::Task['tool:show:all'].invoke
      exit(0)
    end

    $stdout.puts('tool:show[id]')
    tool = RailsLti2Provider::Tool.select(:id, :uuid, :shared_secret, :status, :tenant_id).find_by(lti_version: '1.3.0', id: id)
    abort("The tool with ID #{id} does not exist") if tool.blank?

    puts(tool.to_json)
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  namespace :destroy do
    desc 'Destroy a tool by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts("tool:destroy:by[#{args[:key]},#{args[:value]}]")

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

      TaskHelpers.tool_destroy_by(key.to_sym, value)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Destroy a tool by ID [id]'
  task :destroy, [:id] => :environment do |_t, args|
    $stdout.puts("tool:destroy[#{args[:id]}]")

    # ID.
    id = args[:id]
    if id.blank?
      $stdout.puts('What is the ID?')
      id = $stdin.gets.strip
    end
    abort('The ID must be valid.') if id.blank?

    TaskHelpers.tool_destroy_by(:id, id)
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  namespace :settings do
    desc 'Show settings for tool by ID [id].'
    task :show, [:id] => :environment do |_t, args|
      id = args[:id]
      abort('The ID is required') if id.blank?

      $stdout.puts("tool:settings:show[#{args[:id]}]")

      tool = RailsLti2Provider::Tool.find_by(lti_version: '1.3.0', id: id)
      abort("The tool with ID #{id} does not exist") if tool.blank?

      output = "{'id': '#{tool.id}', 'uuid': '#{tool.uuid}', 'shared_secret': '#{tool.shared_secret}'}"
      output += " is #{tool.status}"
      output += " and linked to tenant '#{tool.tenant.uid}'"
      puts(output)
      $stdout.puts("\n")
      $stdout.puts("tool_settings: \n#{JSON.parse(tool.tool_settings).to_yaml}")
      $stdout.puts("\n")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Update a tool by ID with Key and Value [id,key,value]'
    task :update, [:id, :key, :value] => :environment do |_t, args|
      # ID.
      id = args[:id]
      if id.blank?
        $stdout.puts('What is the ID?')
        id = $stdin.gets.strip
      end
      abort('The ID cannot be blank.') if id.blank?

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

      $stdout.puts("tool:settings:update[#{id},#{key},#{value}]")

      tool = RailsLti2Provider::Tool.find(id)
      abort("The tool with id = #{id} does not exist") if tool.blank?

      tool_settings = JSON.parse(tool.tool_settings)

      tool_settings[key] = value
      tool.update(tool_settings: tool_settings.to_json)

      Rake::Task['tool:settings:show'].invoke(id)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Show settings for tool by ID [id].'
  task :settings, [:id] => :environment do |_t, args|
    id = args[:id]
    abort('The ID is required') if id.blank?

    Rake::Task['tool:settings:show'].invoke(id)
  end

  namespace :keys do
    desc 'Show keys for tool by ID [id].'
    task :show, [:id] => :environment do |_t, args|
      id = args[:id]
      abort('The ID is required') if id.blank?

      $stdout.puts("tool:keys:show[#{args[:id]}]")

      tool = RailsLti2Provider::Tool.find_by(lti_version: '1.3.0', id: id)
      abort("The tool with ID #{id} does not exist") if tool.blank?

      key_pair_token = JSON.parse(tool.tool_settings)['rsa_key_pair_token']
      abort("The key_pair_token for #{id} does not exist") if key_pair_token.blank?

      keys = RsaKeyPair.find_by(token: key_pair_token)

      puts(tool.to_json)

      $stdout.puts("\n")
      $stdout.puts("Private Key:\n#{keys.private_key}")
      $stdout.puts("\n")
      $stdout.puts("Public Key:\n#{keys.public_key}")
      $stdout.puts("\n")
      $stdout.puts("Public Key URL:\n#{registration_pub_keyset_url(protocol: 'https', key_token: key_pair_token)}")
      $stdout.puts("\n")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Generate new key pair for existing Tool configuration'
    task :reset, [:id] => :environment do |_t, args|
      id = args[:id]
      abort('The ID is required') if id.blank?

      $stdout.puts("tool:keys:reset[#{args[:id]}]")

      tool = RailsLti2Provider::Tool.find_by(lti_version: '1.3.0', id: id)
      abort("The tool with ID #{id} does not exist") if tool.blank?

      # Setting keys
      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      key_pair_token = Digest::MD5.hexdigest(SecureRandom.uuid)

      tool_settings = JSON.parse(tool.tool_settings)
      key_pair_id = tool_settings['rsa_key_pair_id']
      key_pairs = RsaKeyPair.find(key_pair_id)
      key_pairs.update({ private_key: private_key, public_key: public_key, token: key_pair_token })

      tool_settings['rsa_key_pair_token'] = key_pair_token
      tool.update(tool_settings: tool_settings.to_json)

      Rake::Task['tool:keys:show'].invoke(id)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Show keys for tool by ID [id].'
  task :keys, [:id] => :environment do |_t, args|
    id = args[:id]
    abort('The ID is required') if id.blank?

    Rake::Task['tool:keys:show'].invoke(id)
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  desc 'Update a tool by ID with Key and Value [id,key,value]'
  task :update, [:id, :key, :value] => :environment do |_t, args|
    $stdout.puts('tool:update[id,key,value]')

    # ID.
    id = args[:id]
    if id.blank?
      $stdout.puts('What is the ID?')
      id = $stdin.gets.strip
    end
    abort('The ID cannot be blank.') if id.blank?

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

    tool = RailsLti2Provider::Tool.find(id)
    abort("The tool with id = #{id} does not exist") if tool.blank?
    tool[key.to_sym] = value
    tool.save
    Rake::Task['tool:show'].invoke(id)
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  desc 'Lists the Registration Configuration URLs need to register an app [app]'
  task :url, [] => :environment do |_t|
    $stdout.puts("Tool URL:\n#{openid_launch_url(protocol: 'https')}")
    $stdout.puts("\n")
    $stdout.puts("Deep Link URL:\n#{deep_link_request_launch_url(protocol: 'https')}")
    $stdout.puts("\n")
    $stdout.puts("Initiate login URL:\n#{openid_login_url(protocol: 'https')}")
    $stdout.puts("\n")
    $stdout.puts(format("Redirection URI(s):\n#{openid_launch_url(protocol: 'https')}\n#{deep_link_request_launch_url(protocol: 'https')}"))
    $stdout.puts("\n")
    $stdout.puts("Dynamic Registration URL:\n#{registration_url(protocol: 'https')}")
    $stdout.puts("\n")
  end

  desc 'Deletes the tool keys inside the temporary bbb-lti folder'
  task :clear_tmp, [] => :environment do |_t|
    storage = TemporaryStorage.new

    # Removes everything inside the bbb-lti folder
    FileUtils.rm_rf(Dir["#{storage.temp_folder}/*"])
  end

  namespace :enable do
    desc 'Enable a tool by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts("tool:enable:by[#{args[:key]},#{args[:value]}]")

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

    desc 'Enable all tools'
    task all: :environment do |_t|
      $stdout.puts('tool:enable:all')

      tools = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
      tools.each do |tool|
        TaskHelpers.tool_enable_by(:id, tool.id)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Enable a tool by ID [id]'
  task :enable, [:id] => :environment do |_t, args|
    $stdout.puts("tool:enable[#{args[:id]}]")

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
    desc 'Disable a tool by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts("tool:disable:by[#{args[:key]},#{args[:value]}]")

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

    desc 'Disable all tools'
    task all: :environment do |_t|
      $stdout.puts('tool:disable:all')

      tools = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
      tools.each do |tool|
        TaskHelpers.tool_disable_by(:id, tool.id)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Disable a tool by ID [id]'
  task :disable, [:id] => :environment do |_t, args|
    $stdout.puts("tool:disable[#{args[:id]}]")

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

desc 'Tool tasks'
task tool: :environment do |_t|
  Rake::Task['tool:show'].invoke
rescue StandardError => e
  puts(e.backtrace)
  exit(1)
end
