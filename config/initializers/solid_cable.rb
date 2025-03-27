# frozen_string_literal: true

# This initializer ensures SolidCable uses the correct configuration
# settings, regardless of YAML parsing issues

# Only configure if SolidCable is defined
Rails.application.config.to_prepare do
  if defined?(SolidCable)
    # Set values that SolidCable can properly parse
    # SolidCable expects polling_interval and message_retention to be strings
    # in the format "1.seconds" or "1.day"
    if SolidCable.instance_variable_get(:@polling_interval).is_a?(Float)
      SolidCable.instance_variable_set(:@polling_interval, "1.seconds")
    end
    
    if SolidCable.instance_variable_get(:@message_retention).is_a?(Integer)
      SolidCable.instance_variable_set(:@message_retention, "1.day")
    end
    
    if !SolidCable.instance_variable_defined?(:@autotrim) || 
       SolidCable.instance_variable_get(:@autotrim).nil?
      SolidCable.instance_variable_set(:@autotrim, true)
    end
  end
end 