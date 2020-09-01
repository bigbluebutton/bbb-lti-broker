class CreateRailsLti2ProviderTenants < ActiveRecord::Migration[6.0]
  def change
    create_table :rails_lti2_provider_tenants do |t|
      t.string :uuid

      t.timestamps
    end
  end
end
