# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
# include BbbLtiBroker::Helpers

namespace :db do
  namespace :tenants do
    desc 'Add a new tenant - add[uid]'
    task :add, [:uid] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:uid]
        puts('No uid provided')
        exit(1)
      end
      tenant = RailsLti2Provider::Tenant.find_by(uid: args[:uid])
      unless tenant.nil?
        puts("Tenant '#{args[:uuid]}' already exists, it can not be added")
        exit(1)
      end
      RailsLti2Provider::Tenant.create!(uid: args[:uid])
      puts("Added '#{args[:uid]}' tenant")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc "Delete an existent tenant and associated keys if exists [uid]'"
    task :delete, [:uid] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:uid]
        puts('No uid provided')
        puts("Tenant '#{args[:uid]}' can not be removed because it is used by default")
        exit(1)
      end
      tenant = RailsLti2Provider::Tenant.find_by(uid: args[:uid])
      if tenant.nil?
        puts("Key '#{args[:uid]}' does not exist, it can not be deleted")
        exit(1)
      end
      puts("Deleting keys for tenant '#{tenant.uid}'")
      RailsLti2Provider::Tool.delete_all(tenant: tenant)
      puts("Deleting tenant '#{tenant.uid}'")
      tenant.delete
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Delete all existent tenants and all associated keys'
    task :deleteall, [] => :environment do |_t|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      tenants = RailsLti2Provider::Tenant.all
      tenants.each do |tenant|
        next if tenant.uid.empty?

        puts("Deleting keys for tenant '#{tenant.uid}'")
        RailsLti2Provider::Tool.delete_all(tenant: tenant)
        puts("Deleting tenant '#{tenant.uid}'")
        tenant.delete
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Show all existent tenants'
    task :showall, [] => :environment do |_t|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      tenants = RailsLti2Provider::Tenant.all
      tenants.each do |tenant|
        puts("Tenant with uid '#{tenant.uid}' has key '#{tenant.id}'")
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end
end
