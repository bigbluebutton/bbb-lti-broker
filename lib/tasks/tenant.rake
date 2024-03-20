# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
require_relative 'task_helpers'

namespace :tenant do
  desc 'Add a new tenant - new[uid]'
  task :new, [:uid] => :environment do |_t, args|
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

  namespace :destroy do
    desc 'Destroy all existent tenants and all associated keys'
    task :all, [] => :environment do |_t|
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
  end

  desc "Destroy an existent tenant and associated keys if exists [uid]'"
  task :destroy, [:uid] => :environment do |_t, args|
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

  namespace :show do
    desc 'Show all existent tenants'
    task :all, [] => :environment do |_t|
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

  desc 'Show all existent tenants'
  task :show, [] => :environment do |_t|
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

  namespace :settings do
    desc 'Show settings for a tenant. If no id is specified, settings for all tenants will be shown'
    task :show, [:uid] => :environment do |_t, args|
      tenant_uid = args[:uid] || ''

      if tenant_uid.present?
        tenant = TaskHelpers.tenant_by('uid', tenant_uid)
        
        puts("Settings for tenant #{tenant.uid}: \n #{tenant.settings.to_yaml}") unless tenant.nil?
      else
        puts(TaskHelpers.tenant_all('settings').to_yaml)
      end
    end

    desc 'Add a new tenant setting'
    task :upsert, [:uid, :key, :value] => :environment do |_t, args|
      tenant_uid = args[:uid] || ''
      key = args[:key]
      value = args[:value]

      unless key.present? && value.present?
        puts('Error: key and value are required to create a tenant setting')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_uid)
      if tenant.nil?
        puts("Tenant '#{tenant_uid}' does not exist.")
        exit(1)
      end

      # Add the setting
      tenant.settings[key] = value
      tenant.save!

      puts("Added setting #{key}=#{value} to tenant #{tenant_uid}")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Destroy a setting'
    task :destroy, [:uid, :key] => :environment do |_t, args|
      tenant_uid = args[:uid] || ''
      key = args[:key]

      if key.blank?
        puts('Error: The setting key is required to delete a tenant setting')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_uid)
      if tenant.nil?
        puts("Tenant '#{tenant_uid}' does not exist.")
        exit(1)
      end

      puts("Key '#{key}' not found for tenant #{tenant}") unless tenant.settings[key]

      tenant.settings.delete(key)
      tenant.save!

      puts("Setting #{key} for tenant '#{tenant_uid}' has been deleted")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  namespace :metadata do
    desc 'Show metadata for a tenant. If no id is specified, metadata for all tenants will be shown'
    task :show, [:uid] => :environment do |_t, args|
      tenant_uid = args[:uid] || ''

      if tenant_uid.present?
        tenant = TaskHelpers.tenant_by('uid', tenant_uid)
        
        puts("Metadata for tenant #{tenant.uid}: \n #{tenant.metadata.to_yaml}") unless tenant.nil?
      else
        puts(TaskHelpers.tenant_all('metadata').to_yaml)
      end
    end
  end

  namespace :registration_token do
    desc 'New registration_token for a tenant'
    task :new, [:uid] => :environment do |_t, args|
      tenant_uid = args[:uid] || ''

      # Key.
      uid = args[:uid]
      if uid.blank?
        $stdout.puts('What is the UID for the tenant?')
        uid = $stdin.gets.strip
      end
      abort('The UID cannot be blank.') if uid.blank?

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{args[:uuid]}' does not exist")
        exit(1)
      end

      # Add the registration_token
      tenant.metadata['registration_token'] = Digest::MD5.hexdigest(SecureRandom.uuid)
      tenant.metadata['registration_token_expire'] = 1.hour.from_now
      tenant.save!
      puts("Metadata for tenant #{tenant.uid}: \n #{tenant.metadata.to_yaml}") unless tenant.nil?
    end

    desc 'Expire registration_token for a tenant'
    task :expire, [:uid] => :environment do |_t, args|
      tenant_uid = args[:uid] || ''

      # Key.
      uid = args[:uid]
      if uid.blank?
        $stdout.puts('What is the UID for the tenant?')
        uid = $stdin.gets.strip
      end
      abort('The UID cannot be blank.') if uid.blank?

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{args[:uuid]}' does not exist")
        exit(1)
      end

      # Expire the registration_token
      tenant.metadata['registration_token_expire'] = Time.current
      tenant.save!
      puts("Metadata for tenant #{tenant.uid}: \n #{tenant.metadata.to_yaml}") unless tenant.nil?
    end
  end
end
