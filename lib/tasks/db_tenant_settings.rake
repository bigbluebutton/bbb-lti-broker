# frozen_string_literal: true

require 'bbb_lti_broker/helpers'

namespace :db do
  namespace :tenants do
    namespace :settings do
      desc 'Show all settings for a tenant. If no id is specified, settings for all tenants will be shown'
      task :showall, [:uid] => :environment do |_t, args|
        tenant_id = args[:uid] || ''

        if tenant_id.present?
          tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)
          if tenant.nil?
            puts("Tenant '#{tenant_id}' does not exist.")
            exit(1)
          end

          puts("Settings for tenant #{tenant_id}: \n #{tenant.settings}")
        else
          tenants = RailsLti2Provider::Tenant.all
          tenants_list = tenants.map do |t|
            {
              tenant: t.uid,
              settings: t.settings,
            }
          end
          puts(tenants_list)
        end
      end

      desc 'Add a new tenant setting'
      task :upsert, [:uid, :key, :value] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        key = args[:key]
        value = args[:value]

        unless key.present? && value.present?
          puts('Error: key and value are required to create a tenant setting')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)
        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        # Add the setting
        tenant.settings[key] = value
        tenant.save!

        puts("Added setting #{key}=#{value} to tenant #{tenant_id}")
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end

      desc 'Delete a setting'
      task :delete, [:uid, :key] => :environment do |_t, args|
        tenant_id = args[:uid] || ''
        key = args[:key]

        if key.blank?
          puts('Error: The setting key is required to delete a tenant setting')
          exit(1)
        end

        tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_id)
        if tenant.nil?
          puts("Tenant '#{tenant_id}' does not exist.")
          exit(1)
        end

        puts("Key '#{key}' not found for tenant #{tenant}") unless tenant.settings[key]

        tenant.settings.delete(key)
        tenant.save!

        puts("Setting #{key} for tenant '#{tenant_id}' has been deleted")
      rescue StandardError => e
        puts(e.backtrace)
        exit(1)
      end
    end
  end
end
