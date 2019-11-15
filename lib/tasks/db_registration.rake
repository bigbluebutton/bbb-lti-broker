namespace :db do
    namespace :registration do
        desc "Add new Tool configuration"
        task :new, :registration do |t, args|
            begin
                Rake::Task['environment'].invoke
                ActiveRecord::Base.connection
                STDOUT.puts "What is the issuer?"
                issuer = STDIN.gets.strip

                STDOUT.puts "What is the client id?"
                client_id = STDIN.gets.strip

                STDOUT.puts "What is the key set url?"
                key_set_url = STDIN.gets.strip

                STDOUT.puts "What is the auth token url?"
                auth_token_url = STDIN.gets.strip

                STDOUT.puts "What is the auth login url?"
                auth_login_url = STDIN.gets.strip

                STDOUT.puts "What is the private key?"
                tool_private_key = STDIN.gets

                tool_proxy = {
                    lti_version: 'LTI-1p3',
                    issuer: issuer,
                    client_id: client_id,
                    key_set_url: key_set_url,
                    auth_token_url: auth_token_url,
                    auth_login_url: auth_login_url,
                    tool_private_key: tool_private_key
                }
                OpenidRegistration.create!(
                    issuer: issuer,
                    client_id: client_id,
                    key_set_url: key_set_url,
                    auth_token_url: auth_token_url,
                    auth_login_url: auth_login_url,
                    tool_private_key: tool_private_key
                );
            rescue => exception
                puts exception.backtrace
                exit 1
            end
        end
        desc "Delete existing Tool configuration"
        task :delete, :registration do |t, args|
            begin
                Rake::Task['environment'].invoke
                ActiveRecord::Base.connection
                STDOUT.puts "What is the issuer for the registration you wish to delete?"
                issuer = STDIN.gets.strip
                reg = OpenidRegistration.find_registration_by_issuer(issuer)
                reg.destroy
            end
        end
    end
end