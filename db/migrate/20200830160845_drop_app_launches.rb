# frozen_string_literal: true

class DropAppLaunches < ActiveRecord::Migration[6.0]
  def change
    drop_table(:app_launches) do |t|
      t.string(:tool_id)
      t.string(:nonce)
      t.text(:message)

      t.timestamps
    end
  end
end
