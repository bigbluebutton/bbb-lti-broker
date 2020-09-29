# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
# include BbbLtiBroker::Helpers

namespace :db do
  namespace :keys do
    desc 'Add a new blti keypair - add[key,secret,tenant]'
    task :add, [:key, :secret, :tenant] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:key]
        puts('No key provided')
        exit(1)
      end
      unless args[:secret]
        puts('No secret provided')
        exit(1)
      end
      tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant] || '')
      tool = RailsLti2Provider::Tool.find_by(uuid: args[:key], tenant: tenant)
      unless tool.nil?
        puts("Key '#{args[:key]}' already exists, it can not be added")
        exit(1)
      end
      RailsLti2Provider::Tool.create!(uuid: args[:key], shared_secret: args[:secret], lti_version: 'LTI-1p0', tool_settings: 'none', tenant: tenant)
      puts("Added '#{args[:key]}=#{args[:secret]}'#{' for tenant ' + tenant.uid unless tenant.uid.empty?}")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc "Update an existent blti keypair if exists - update[key:secret]'"
    task :update, [:key, :secret, :tenant] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:key]
        puts('No key provided')
        exit(1)
      end
      unless args[:secret]
        puts('No secret provided')
        exit(1)
      end
      tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant] || '')
      tool = RailsLti2Provider::Tool.find_by(uuid: args[:key], tenant: tenant)
      unless tool.nil?
        puts("Key '#{args[:key]}' does not exist, it can not be updated")
        exit(1)
      end
      tool.update!(shared_secret: secret)
      puts("Updated '#{args[:key]}=#{args[:secret]}'#{' for tenant ' + tenant.uid unless tenant.uid.empty?}")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc "Delete an existent blti keypair if exists [key:secret]'"
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
      puts("Deleted '#{args[:key]}'#{' for tenant ' + tenant.uid unless tenant.uid.empty?}")
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
        puts "'#{key.uuid}'='#{key.shared_secret}'" +  for_teanat
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end
end
