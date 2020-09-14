# frozen_string_literal: true

class DropAppLaunches < ActiveRecord::Migration[6.0]
  def change
    drop_table :rails_lti2_provider_launches, if_exists: true
  end
end
