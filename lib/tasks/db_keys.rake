# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
require 'securerandom'
# include BbbLtiBroker::Helpers

namespace :db do
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

    desc 'Show all existent blti keypairs'
    task :showall, [] => :environment do |_t|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      blti_keys = RailsLti2Provider::Tool.all
      blti_keys.each do |key|
        for_teanat = ''
        for_teanat = " for tenant '#{key.tenant.uid}'" unless key.tenant.uid.empty?
        puts("'#{key.uuid}'='#{key.shared_secret}'" +  for_teanat)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

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
  end
end
