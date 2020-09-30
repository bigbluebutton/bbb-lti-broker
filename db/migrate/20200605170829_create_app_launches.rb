# frozen_string_literal: true

class CreateAppLaunches < ActiveRecord::Migration[6.0]
  def change
    create_table(:app_launches) do |t|
      t.string(:tool_id)
      t.string(:nonce)
      t.text(:message)

      t.timestamps
    end
  end
end
