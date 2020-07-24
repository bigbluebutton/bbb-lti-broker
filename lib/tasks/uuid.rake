# frozen_string_literal: true

desc 'Generate a cryptographically unique uuid \
      (this is typically used to identify the app instance \
       through product_instance_guid)'
task :uuid, [] => :environment do
  puts SecureRandom.uuid
end
