# frozen_string_literal: true

class AddUsernamePasswordToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table(:users, bulk: true) do |t|
      t.string(:username)
      t.string(:password_digest)
      t.boolean(:admin)
    end
    add_index(:users, :username, unique: true)
  end
end

change_table :users, bulk: true
