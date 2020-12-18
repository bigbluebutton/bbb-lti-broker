# frozen_string_literal: true

namespace :db do
  namespace :accounts do
    desc 'Add an admin account'
    task :admin, [:username] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      unless args[:username]
        puts('No Username provided')
        exit(1)
      end

      puts('What is the password?')
      password = STDIN.noecho(&:gets).strip
      puts('Confirm password:')
      confirm_password = STDIN.noecho(&:gets).strip

      unless password == confirm_password
        puts('Passwords don\'t match')
        exit(1)
      end

      if User.find_by_username(args[:username])
        puts('User already exists')
        exit(1)
      end

      User.create!(username: args[:username], password: password, admin: true)
      puts('User has been created')
    end
  end
end
