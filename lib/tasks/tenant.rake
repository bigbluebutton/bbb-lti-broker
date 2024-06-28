# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
require_relative 'task_helpers'

namespace :tenant do
  desc 'Add a new tenant - new[uid]'
  task :new, [:uid] => :environment do |_t, args|
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
    desc 'Show all tenants'
    task :all, [] => :environment do |_t|
      $stdout.puts('tenant:show:all')
      tenants = RailsLti2Provider::Tenant.select(:id, :uid, :settings, :metadata).all
      tenants.each do |tenant|
        puts(tenant.to_json)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Show a tenant by [key,value]'
    task :by, [:key, :value] => :environment do |_t, args|
      $stdout.puts('tenant:show:by[key,value]')

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

      tenant = RailsLti2Provider::Tenant.select(:id, :uid, :settings, :metadata).find_by(key.to_sym => value)
      abort("The tenant with #{key} = #{value} does not exist") if tenant.blank?

      puts(tenant.to_json)
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Show all existent tenants'
  task :show, [:id] => :environment do |_t, args|
    # ID. Default to all if blank.
    id = args[:id]
    if id.blank?
      Rake::Task['tenant:show:all'].invoke
      exit(0)
    end

    $stdout.puts('tenant:show[id]')
    tenant = RailsLti2Provider::Tenant.select(:id, :uid, :settings, :metadata).find(id)
    puts(tenant.to_json)
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  namespace :settings do
    desc 'Show settings for a tenant. If no id is specified, settings for all tenants will be shown'
    task :show, [:uid] => :environment do |_t, args|
      uid = args[:uid]

      if uid.present?
        tenant = TaskHelpers.tenant_by('uid', uid)

        puts("Settings for tenant #{tenant.uid}: \n #{tenant.settings.to_yaml}") unless tenant.nil?
      else
        puts(TaskHelpers.tenant_all('settings').to_yaml)
      end
    end

    desc 'Add a new tenant setting'
    task :upsert, [:uid, :key, :value] => :environment do |_t, args|
      uid = args[:uid] || ''
      key = args[:key]
      value = args[:value]

      unless key.present? && value.present?
        puts('Error: key and value are required to create a tenant setting')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{uid}' does not exist.")
        exit(1)
      end

      # Add the setting
      tenant.settings[key] = value
      tenant.save!

      puts("Added setting #{key}=#{value} to tenant #{uid}")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Destroy a setting'
    task :destroy, [:uid, :key] => :environment do |_t, args|
      uid = args[:uid] || ''
      key = args[:key]

      if key.blank?
        puts('Error: The setting key is required to delete a tenant setting')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{uid}' does not exist.")
        exit(1)
      end

      puts("Key '#{key}' not found for tenant #{tenant}") unless tenant.settings[key]

      tenant.settings.delete(key)
      tenant.save!

      puts("Setting #{key} for tenant '#{uid}' has been deleted")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  desc 'Tenant Settings task'
  task settings: :environment do |_t|
    Rake::Task['tenant:settings:show'].invoke
  rescue StandardError => e
    puts(e.backtrace)
    exit(1)
  end

  namespace :metadata do
    desc 'Show metadata for a tenant. If no id is specified, metadata for all tenants will be shown'
    task :show, [:uid] => :environment do |_t, args|
      uid = args[:uid] || ''

      if uid.present?
        tenant = TaskHelpers.tenant_by('uid', uid)

        puts("Metadata for tenant #{tenant.uid}: \n #{tenant.metadata.to_yaml}") unless tenant.nil?
      else
        puts(TaskHelpers.tenant_all('metadata').to_yaml)
      end
    end

    desc 'Destroy a metadata'
    task :destroy, [:uid, :key] => :environment do |_t, args|
      uid = args[:uid]
      key = args[:key]

      if key.blank?
        puts('Error: The setting key is required to delete a tenant metadata')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{uid}' does not exist.")
        exit(1)
      end

      puts("Key '#{key}' not found for tenant #{tenant}") unless tenant.metadata[key]

      tenant.metadata.delete(key)
      tenant.save!

      puts("Metadata #{key} for tenant '#{uid}' has been deleted")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end

  namespace :activation_code do
    desc 'New activation_code for a tenant'
    task :new, [:uid, :hours] => :environment do |_t, args|
      # Key.
      uid = args[:uid]
      if uid.blank?
        $stdout.puts('What is the UID for the tenant?')
        uid = $stdin.gets.strip
      end
      abort('The UID cannot be blank.') if uid.blank?

      # Hours to expire.
      hours = args[:hours] || 1

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{args[:uuid]}' does not exist")
        exit(1)
      end

      # Add the activation_code
      tenant.metadata['activation_code'] = Digest::MD5.hexdigest(SecureRandom.uuid)
      tenant.metadata['activation_code_expire'] = hours.hour.from_now
      tenant.save!
      puts("Metadata for tenant #{tenant.uid}: \n #{tenant.metadata.to_yaml}") unless tenant.nil?
    end

    desc 'Expire activation_code for a tenant'
    task :expire, [:uid] => :environment do |_t, args|
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

      # Expire the activation_code
      tenant.metadata['activation_code_expire'] = Time.current
      tenant.save!
      puts("Metadata for tenant #{tenant.uid}: \n #{tenant.metadata.to_yaml}") unless tenant.nil?
    end

    desc 'Show activation_code for a tenant'
    task :show, [:uid] => :environment do |_t, args|
      # Key.
      uid = args[:uid]
      if uid.blank?
        $stdout.puts('What is the UID for the tenant?')
        uid = $stdin.gets.strip
      end
      abort('The UID cannot be blank.') if uid.blank?

      Rake::Task['tenant:metadata:show'].invoke(uid)
    end
  end

  desc 'Show activation_code for a tenant'
  task :activation_code, [:uid] => :environment do |_t, args|
    Rake::Task['tenant:activation_code:show'].invoke(args[:uid])
  end

  namespace :ext_params do
    ext_params_key = 'ext_params'

    desc 'Add an extra parameter to be passed to BBB on join or create'
    task :upsert, [:uid, :action, :source, :target] => :environment do |_t, args|
      # the key is the name of the param coming from the LMS, the value is the name of the param to be sent to BBB
      uid = args[:uid] || ''
      action = args[:action].downcase
      key = args[:source]
      value = args[:target]

      unless action.present? && %w[join create].include?(action)
        puts('Error: please specify whether the params should be passed on join or create')
        exit(1)
      end

      unless key.present? && value.present?
        puts('Error: you must specify a key and value for the extra parameter')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{uid}' does not exist.")
        exit(1)
      end

      tenant.settings[ext_params_key] ||= { 'join' => {}, 'create' => {} }
      tenant.settings[ext_params_key][action][key] = value
      tenant.save!

      puts("The extra parameter #{key}=#{value} was added to tenant #{uid}")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Delete an extra parameter mapping'
    task :destroy, [:uid, :action, :source] => :environment do |_t, args|
      uid = args[:uid] || ''
      action = args[:action].downcase
      key = args[:source]

      unless action.present? && %w[join create].include?(action)
        puts('Error: please specify whether the params is passed on join or create')
        exit(1)
      end

      if key.blank?
        puts('Error: you must specify the key you want to be deleted')
        exit(1)
      end

      tenant = RailsLti2Provider::Tenant.find_by(uid: uid)
      if tenant.nil?
        puts("Tenant '#{uid}' does not exist.")
        exit(1)
      end

      tenant.settings[ext_params_key][action].delete(key)
      tenant.save!

      puts("Successfully deleted extra parameter #{key} for tenant #{uid}")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end
end

desc 'Tenant task'
task tenant: :environment do |_t|
  Rake::Task['tenant:show'].invoke
rescue StandardError => e
  puts(e.backtrace)
  exit(1)
end
