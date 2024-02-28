# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
require 'securerandom'

namespace :keys do
  desc 'Add a new blti keypair - add[key,secret,tenant]. If "key" or "secret" are empty, a value will be generated for you'
  task :add, [:key, :secret, :tenant] => :environment do |_t, args|
    include BbbLtiBroker::Helpers
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
    unless args[:key] || args[:tenant]
      puts('You must provide either a key or tenant')
      exit(1)
    end

    key = args[:key] || SecureRandom.alphanumeric(12)
    secret = args[:secret] || SecureRandom.alphanumeric(16)
    tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant] || '')
    tool = RailsLti2Provider::Tool.find_by(uuid: key)
    unless tool.nil?
      puts("Key '#{key}' already exists, it can not be added")
      exit(1)
    end
    RailsLti2Provider::Tool.create!(uuid: key, shared_secret: secret, lti_version: 'LTI-1p0', tool_settings: 'none', tenant: tenant)
    puts("Added '#{key}=#{secret}'#{" for tenant #{tenant.uid}" unless tenant.uid.empty?}")

    url = Rails.configuration.url_host
    url_root = Rails.configuration.relative_url_root[1..] # remove leading '/'
    url = "https://#{url}" unless url.first(4) == 'http'
    url += '/' unless url.last(1) == '/'
    url += "#{url_root}/rooms/messages/blti"

    puts("Key:\t#{key}\nSecret:\t#{secret}\nURL:\t#{url}")
    puts
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  desc "Update an existent blti keypair if exists - update[key,secret,Tenant]'"
  task :update, [:key, :secret, :tenant] => :environment do |_t, args|
    include BbbLtiBroker::Helpers
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
    unless args[:key]
      puts('No key provided')
      exit(1)
    end
    secret = args[:secret] || Array.new(12) { (rand(122 - 97) + 97).chr }.join
    tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant] || '')
    tool = RailsLti2Provider::Tool.find_by(uuid: args[:key])
    unless tool
      puts("Key '#{args[:key]}' does not exist, it can not be updated")
      exit(1)
    end
    tool.update!(shared_secret: secret, tenant: tenant)
    puts("Updated '#{args[:key]}=#{secret}'#{" for tenant #{tenant.uid}" unless tenant.uid.empty?}")
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  desc "Delete an existent blti keypair if exists [key,secret,tenant]'"
  task :delete, [:key, :tenant] => :environment do |_t, args|
    include BbbLtiBroker::Helpers
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
    unless args[:key]
      puts('No key provided')
      exit(1)
    end
    tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant] || '')
    tool = RailsLti2Provider::Tool.find_by(uuid: args[:key], tenant: tenant)
    if tool.nil?
      puts("Key '#{args[:key]}' does not exist, it can not be deleted")
      exit(1)
    end
    tool.delete
    puts("Deleted '#{args[:key]}'#{" for tenant #{tenant.uid}" unless tenant.uid.empty?}")
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  desc 'Delete all existent blti keypairs'
  task :deleteall, [] => :environment do |_t|
    include BbbLtiBroker::Helpers
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
    puts('Deleting all LTI-1p0 keys')
    RailsLti2Provider::Tool.delete_all(lti_version: 'LTI-1p0', tool_settings: 'none')
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  # desc 'Show all existent blti keypairs for backward compatibil'
  # task :showall, [] => :environment do |_t|
  #   Rake::Task['db:keys'].invoke
  # end

  desc 'Show a key-secret pair if it exists'
  task :show, [:key, :tenant] => :environment do |_t, args|
    Rake::Task['environment'].invoke
    ActiveRecord::Base.connection
    unless args[:key]
      puts('No key provided')
      exit(1)
    end
    tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant] || '')
    tool = RailsLti2Provider::Tool.find_by(uuid: args[:key], tenant: tenant)
    for_tenant = tenant.uid.empty? ? '' : tenant.uid
    abort("Key '#{args[:key]}' does not exist for tenant '#{for_tenant}'.") if tool.nil?

    tool_name = Rails.configuration.default_tool
    url = Rails.configuration.url_host
    url_root = Rails.configuration.relative_url_root[1..] # remove leading '/'
    url = "https://#{url}" unless url.first(4) == 'http'
    url += '/' unless url.last(1) == '/'
    url += "#{url_root}/#{tool_name}/messages/blti"

    puts("Key:\t#{tool.uuid}\nSecret:\t#{tool.shared_secret}\nURL:\t#{url}")
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  namespace :enable do
    desc 'Enable a key by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts("db:key:enable:by[#{args[:key]},#{args[:value]}]")

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

    desc 'Enable all keys'
    task all: :environment do |_t|
      $stdout.puts('db:key:enable:all')

      keys = RailsLti2Provider::Tool.where.not(lti_version: '1.3.0')
      keys.each do |key|
        TaskHelpers.tool_enable_by(:id, key.id)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Enable a key by ID [id]'
  task :enable, [:id] => :environment do |_t, args|
    $stdout.puts("db:key:enable[#{args[:id]}]")

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
    desc 'Disable a key by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts("db:key:disable:by[#{args[:key]},#{args[:value]}]")

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

    desc 'Disable all keys'
    task all: :environment do |_t|
      $stdout.puts('db:key:disable:all')

      keys = RailsLti2Provider::Tool.where.not(lti_version: '1.3.0')
      keys.each do |key|
        TaskHelpers.tool_disable_by(:id, key.id)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Disable a key by ID [id]'
  task :disable, [:id] => :environment do |_t, args|
    $stdout.puts("db:key:disable[#{args[:id]}]")

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

desc 'Show all existent blti keypairs'
task :keys, [] => :environment do |_t|
  include BbbLtiBroker::Helpers
  Rake::Task['environment'].invoke
  ActiveRecord::Base.connection
  blti_keys = RailsLti2Provider::Tool.all
  blti_keys.each do |key|
    next if key.lti_version == '1.3.0'

    output = "{'id': '#{key.id}', 'uuid': '#{key.uuid}', 'shared_secret': '#{key.shared_secret}'}"
    output += " for tenant '#{key.tenant.uid}'" unless key.tenant.uid.empty?
    output += " is #{key.status}"
    puts(output)
  end
rescue StandardError => e
  puts(e.backtrace)
  exit(1)
end
