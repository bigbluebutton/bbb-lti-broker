# frozen_string_literal: true

class AddToolAssociationToTenant < ActiveRecord::Migration[4.2]
  def self.up
    add_column(:rails_lti2_provider_tools, :tenant_id, :integer)
    add_index('rails_lti2_provider_tools', ['tenant_id'], name: 'index_tenant_id')
  end

  def self.down
    remove_column(:rails_lti2_provider_tools, :tenant_id)
  end
end
