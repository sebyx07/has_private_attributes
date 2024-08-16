# frozen_string_literal: true

class Configuration
  include HasPrivateAttributes

  private_attribute :default_settings do
    {
      timeout: 30,
      retries: 3,
      log_level: :info
    }
  end

  def self.timeout
    default_settings[:timeout]
  end

  def self.retries
    default_settings[:retries]
  end
end

# puts Configuration.timeout # => 30
# puts Configuration.retries # => 3
