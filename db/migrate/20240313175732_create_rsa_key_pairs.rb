# frozen_string_literal: true

class CreateRsaKeyPairs < ActiveRecord::Migration[6.1]
  def self.up
    create_table :rsa_key_pairs do |t|
      t.text :private_key
      t.text :public_key

      t.timestamps null:false, precision: 6
    end

    add_index(:rsa_key_pairs, :id, unique: true, if_not_exists: true)

    # data migration
    tools = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
    tools.find_each do |tool|
      # identify the files
      tool_settings = JSON.parse(tool.tool_settings)
      key_token = tool_settings['tool_private_key'].split('/')[-2]
      private_key_file = Rails.root.join(".ssh/#{key_token}/priv_key")
      public_key_file = Rails.root.join(".ssh/#{key_token}/pub_key")

      # read keys from file
      begin
        private_key = File.read(private_key_file)
        public_key = File.read(public_key_file)
      rescue StandardError => e
        puts("Error pub_keyset\n#{e}")
        next
      end

      # create the new record
      rsa_key_pair = RsaKeyPair.create(
        private_key: private_key,
        public_key: public_key,
      )

      # update existing tool
      tool_settings['rsa_key_pair_id'] = rsa_key_pair.id
      tool.update(tool_settings: tool_settings.to_json)
      puts("tool [#{tool.id}] has been migrated")
    end
  end

  def self.down
    remove_index(:rsa_key_pairs, :id) if index_exists?(:rsa_key_pairs, :id)
    drop_table :rsa_key_pairs, if_exists: true
  end
end
