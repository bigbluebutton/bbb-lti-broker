# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'rake'


ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'rake'
require 'webmock/minitest'
# require 'minitest/stub_any_instance'


BbbLtiBroker::Application.load_tasks if Rake::Task.tasks.empty?

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Make support methods accessible to tests
    Dir[Rails.root.join('test/support/**/*.rb')].sort.each { |f| require f }
  end
end
