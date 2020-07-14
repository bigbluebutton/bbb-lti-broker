# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'bbb_lti_broker/helpers'
# include BbbLtiBroker::Helpers

namespace :db do
  namespace :keys do
    desc "Add a new blti keypair (e.g. 'rake db:keys:add[key:secret]')"
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

    desc "Update an existent blti keypair if exists (e.g. 'rake db:keys:update[key:secret]')"
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

    desc "Delete an existent blti keypair if exists (e.g. 'rake db:keys:delete[key:secret]')"
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
