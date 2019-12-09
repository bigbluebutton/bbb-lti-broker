namespace :db do
    namespace :registration do
        desc "Add new Tool configuration"
        task :new, :registration do |t, args|
            begin
                Rake::Task['environment'].invoke
                ActiveRecord::Base.connection
                STDOUT.puts "What is the issuer?"
                issuer = STDIN.gets.strip

                unless issuer.present?
                    abort("The issuer must be valid.")
                    return
                end

                STDOUT.puts "What is the client id?"
                client_id = STDIN.gets.strip

                STDOUT.puts "What is the key set url?"
                key_set_url = STDIN.gets.strip

                STDOUT.puts "What is the auth token url?"
                auth_token_url = STDIN.gets.strip

                STDOUT.puts "What is the auth login url?"
                auth_login_url = STDIN.gets.strip

                private_key = OpenSSL::PKey::RSA.generate 4096
                public_key = private_key.public_key
                key_dir = Digest::MD5.hexdigest issuer
                Dir.mkdir('.ssh/' + key_dir) unless Dir.exist?('.ssh/' + key_dir)

                File.open(File.join(Rails.root, '.ssh', key_dir, "priv_key"), "w") do |f|
                    f.puts private_key.to_s
                end
    
                File.open(File.join(Rails.root, '.ssh', key_dir, "pub_key"), "w") do |f|
                    f.puts public_key.to_s
                end

                reg = {
                    issuer: issuer,
                    client_id: client_id,
                    key_set_url: key_set_url,
                    auth_token_url: auth_token_url,
                    auth_login_url: auth_login_url,
                    tool_private_key: "#{Rails.root}/.ssh/#{key_dir}/priv_key"
                }

                RailsLti2Provider::Tool.create(
                    uuid: issuer,
                    shared_secret: client_id,
                    tool_settings: reg.to_json,
                    lti_version: '1.3.0'
                )

                puts public_key.to_s

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