# frozen_string_literal: true

require 'bbb_lti_broker/helpers'
# include BbbLtiBroker::Helpers

namespace :db do
  namespace :keys do
    desc 'Add a new blti keypair - add[key:secret]'
    task :add, [:keys] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      blti_keys = BbbLtiBroker::Helpers.string_to_hash(args[:keys] || '')
      if blti_keys.empty?
        puts('No keys provided')
        exit(1)
      end
      blti_keys.each do |key, secret|
        puts "Adding '#{key}=#{secret}'"
        tool = RailsLti2Provider::Tool.find_by(uuid: key, lti_version: 'LTI-1p0', tool_settings: 'none')
        if tool
          puts("Key '#{key}' already exists, it can not be added")
        else
          RailsLti2Provider::Tool.create!(uuid: key, shared_secret: secret, lti_version: 'LTI-1p0', tool_settings: 'none')
        end
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc "Update an existent blti keypair if exists - update[key:secret]'"
    task :update, [:keys] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      blti_keys = BbbLtiBroker::Helpers.string_to_hash(args[:keys] || '')
      if blti_keys.empty?
        puts('No keys provided')
        exit(1)
      end
      puts(blti_keys.to_s)
      blti_keys.each do |key, secret|
        puts "Updating '#{key}=#{secret}'"
        tool = RailsLti2Provider::Tool.find_by(uuid: key, lti_version: 'LTI-1p0', tool_settings: 'none')
        if !tool
          puts("Key '#{key}' does not exist, it can not be updated")
        else
          tool.update!(shared_secret: secret)
        end
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc "Delete an existent blti keypair if exists [key:secret]'"
    task :delete, [:keys] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      blti_keys = BbbLtiBroker::Helpers.string_to_hash(args[:keys] || '')
      if blti_keys.empty?
        puts('No keys provided')
        exit(1)
      end
      puts(blti_keys.to_s)
      blti_keys.each do |key, _secret|
        puts "Deleting '#{key}'"
        tool = RailsLti2Provider::Tool.find_by(uuid: key, lti_version: 'LTI-1p0', tool_settings: 'none')
        if !tool
          puts("Key '#{key}' does not exist, it can not be deleted")
        else
          tool.delete
        end
      end
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
        puts "'#{key.uuid}'='#{key.shared_secret}'"
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end
  end
end
