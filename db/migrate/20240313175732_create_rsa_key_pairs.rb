class CreateRsaKeyPairs < ActiveRecord::Migration[6.1]
  def self.up
    create_table :rsa_key_pairs do |t|
      t.text :private_key
      t.text :public_key
      t.string :tool_id

      t.timestamps null:false, precision: 6
    end

    # data migration.
  end

  def self.down
    drop_table :rsa_key_pairs, if_exists: true
  end
end
