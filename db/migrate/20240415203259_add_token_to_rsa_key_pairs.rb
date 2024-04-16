# frozen_string_literal: true

class AddTokenToRsaKeyPairs < ActiveRecord::Migration[6.1]
  def up
    return unless table_exists?(:rsa_key_pairs)

    unless column_exists?(:rsa_key_pairs, :token)
      add_column(:rsa_key_pairs, :token, :string)

      #change_column(:rsa_key_pairs, :token, :string, null: false)
    end

    # data migration
    tools = RailsLti2Provider::Tool.where(lti_version: '1.3.0')
    tools.find_each do |tool|
      tool_settings = JSON.parse(tool.tool_settings)
      tool_private_key = tool_settings['tool_private_key']
      rsa_key_pair_id = tool_settings['rsa_key_pair_id']
      rsa_key_pair_token = tool_private_key.split('/')[-2] unless tool_private_key.nil?
      rsa_key_pair_token = Digest::MD5.hexdigest(SecureRandom.uuid) unless rsa_key_pair_token
            
      # update existing RsaKeyPair
      rsa_key_pair = RsaKeyPair.find(rsa_key_pair_id) if rsa_key_pair_id
      rsa_key_pair.update(token: rsa_key_pair_token)

      # update existing Tool
      tool_settings['rsa_key_pair_token'] = rsa_key_pair_token
      tool.update(tool_settings: tool_settings.to_json)
      puts("tool [#{tool.id}] has been migrated")
    end
  end

  def down
    return unless table_exists?(:rsa_key_pairs)

    remove_column(:rsa_key_pairs, :rsa_key_pair_token)
  end
end
