# frozen_string_literal: true

# lib/tasks/task_helpers.rb

module TaskHelpers
  def self.tool_enable_by(key, value)
    tool_update_status_by(key, value, 'enabled')
  end

  def self.tool_disable_by(key, value)
    tool_update_status_by(key, value, 'disabled')
  end

  def self.tool_update_status_by(key, value, status)
    # Check if the RailsLti2Provider::Tool model has a 'key' column
    $stdout.puts("key #{key} does not exist") && return unless RailsLti2Provider::Tool.column_names.include?(key.to_s)

    tool = RailsLti2Provider::Tool.find_by(key.to_sym => value)
    if tool.blank?
      $stdout.puts("value '#{value}' for key '#{key}' was not found")
      return
    end

    tool.status = RailsLti2Provider::Tool.statuses[status.to_sym]
    tool.save

    output = "{'id': '#{tool.id}', 'uuid': '#{tool.uuid}', 'shared_secret': '#{tool.shared_secret}'}"
    output += " for tenant '#{tool.tenant.uid}'" unless tool.tenant.uid.empty?
    output += " is #{tool.status}"
    $stdout.puts(output)
  end
end
