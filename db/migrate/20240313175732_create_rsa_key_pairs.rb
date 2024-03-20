class CreateRsaKeyPairs < ActiveRecord::Migration[6.1]
  def change
    create_table :rsa_key_pairs do |t|
      t.text :private_key
      t.text :public_key
      t.string :tool_id

      t.timestamps null:false, precision: 6
    end
  end
end
