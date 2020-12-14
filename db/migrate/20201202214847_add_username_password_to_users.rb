class AddUsernamePasswordToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :username, :string
    add_column :users, :password_digest, :string
    add_column :users, :admin, :boolean
    add_index :users, :username, unique: true
  end
end
