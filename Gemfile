# frozen_string_literal: true

source 'http://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0', '>= 6.0.5'
# Use sqlite3 as the database for Active Record
gem 'pg', '>= 0.4.4'
# Use Puma as the app server
gem 'puma', '>= 4.3.5'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6.0.0'
# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'
gem 'terser', '~> 1.1.8'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0', '>= 5.0.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'http'

gem 'addressable', '~> 2.7'
gem 'faraday'
gem 'oauthenticator', '~> 1.3'

gem 'bundler', '>=2.1.4'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11', '>= 2.11.2'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'ims-lti', '~> 2.3.1'
gem 'jwt', '~> 2.2.2'
gem 'oauth', '~> 0.5.1'

gem 'doorkeeper', '~> 5.3.3'
gem 'repost', '~> 0.3.8'

gem 'lodash-rails'
gem 'react-rails'

gem 'rails_lti2_provider', git: 'https://github.com/blindsidenetworks/rails_lti2_provider.git', tag: '0.1.1'

gem 'activerecord-session_store'

# frontend
gem 'bootstrap', '~> 4.3.1'
gem 'font-awesome-sass', '~> 5.9.0'
gem 'redis', '~> 4.2'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'rspec'
  gem 'rspec-rails'
end

group :development do
  gem 'rubocop', '~> 0.90.0', require: false
  gem 'rubocop-rails', '~> 2.4.0', require: false
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.0.5'
  gem 'web-console', '>= 4.1.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'minitest-stub_any_instance'
  gem 'webmock'
end

group :production do
  gem 'remote_syslog_logger'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'

gem 'coveralls', require: false
