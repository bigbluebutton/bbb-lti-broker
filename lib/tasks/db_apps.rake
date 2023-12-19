# frozen_string_literal: true

require 'securerandom'
require 'uri'
require 'bbb_lti_broker/helpers'

# include BbbLtiBroker::Helpers

namespace :db do
  namespace :apps do
    desc 'Add a new blti app - add[name,hostname,uid,secret]'
    task :add, [:name, :hostname, :uid, :secret] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:name]
        puts('No app name provided')
        exit(1)
      end
      blti_apps = Doorkeeper::Application.where(name: args[:name])
      unless blti_apps.empty?
        puts("App '#{args[:name]}' already exists, it can not be added")
        exit(1)
      end
      unless args[:hostname]
        puts("Parameters hostname is required, app '#{args[:name]}' can not be added")
        exit(1)
      end
      puts("Adding '#{args.to_hash}'")
      uid = args.[](:uid) || SecureRandom.hex(32)
      secret = args.[](:secret) || SecureRandom.hex(32)

      redirect_uri = (args[:hostname]).to_s
      app = Doorkeeper::Application.create!(name: args[:name], uid: uid, secret: secret, \
                                            redirect_uri: redirect_uri, scopes: 'api')
      app1 = app.attributes.select { |key, _value| %w[name uid secret redirect_uri].include?(key) }
      puts("Added '#{app1.to_json}'")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Update an existent blti app if exists - update[name,hostname,uid,secret]'
    task :update, [:name, :hostname, :uid, :secret] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:name]
        puts('No app name provided')
        exit(1)
      end
      app = Doorkeeper::Application.find_by(name: args[:name])
      if app.nil?
        puts("App '#{args[:name]}' does not exist, it can not be updated")
        exit(1)
      end
      puts("Updating '#{args.to_hash}'")
      app.update!(uid: args[:uid]) if args.[](:uid)
      app.update!(secret: args[:secret]) if args.[](:secret)

      redirect_uri = (args[:hostname]).to_s
      app.update!(redirect_uri: redirect_uri) if args.[](:hostname)
      app1 = app.attributes.select { |key, _value| %w[name uid secret redirect_uri].include?(key) }
      puts("Updated '#{app1.to_json}'")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Delete an existent blti app if exists - delete[name]'
    task :delete, [:name] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:name]
        puts('No app name provided')
        exit(1)
      end
      blti_apps = Doorkeeper::Application.where(name: args[:name])
      if blti_apps.empty?
        puts("App '#{args[:name]}' does not exist, it can not be deleted")
        exit(1)
      end
      blti_apps.each(&:destroy)
      puts("Apps with name '#{args[:name]}' were successfully destroyed")
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Show an existent blti app if exists - show[name]'
    task :show, [:name] => :environment do |_t, args|
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      unless args[:name]
        puts('No app name provided')
        exit(1)
      end
      apps = Doorkeeper::Application.where(name: args[:name])
      if apps.empty?
        puts("App '#{args[:name]}' does not exist, it can not be shown")
        exit(1)
      end
      apps.each do |app|
        app1 = app.attributes.select { |key, _value| %w[name uid secret redirect_uri].include?(key) }
        puts(app1.to_json)
      end
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Delete all existent blti apps'
    task :deleteall, [] => :environment do
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      Doorkeeper::Application.delete_all
      puts('All the registered apps were deleted')
    rescue StandardError => e
      puts(e.backtrace)
      exit(1)
    end

    desc 'Show all existent blti apps'
    task :showall, [] => :environment do
      include BbbLtiBroker::Helpers
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      apps = Doorkeeper::Application.all
      apps.each do |app|
        app1 = app.attributes.select { |key, _value| %w[name uid secret redirect_uri].include?(key) }
        puts(app1.to_json)
      end
    rescue ApplicationRedisRecord::RecordNotFound
      puts(e.backtrace)
      exit(1)
    end
  end
end
