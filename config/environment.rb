# Load the rails application.
require File.expand_path('../application', __FILE__)

# Initialize the rails application.
Ohship::Application.initialize!

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked # We're in smart spawning mode.
      Analytics = AnalyticsRuby  # alias for convenience
      Analytics.init(secret: ANALYTICS_CONFIG["SEGMENT_SECRET"])
    else
      # We're in direct spawning mode. We don't need to
      # do anything.
    end
  end
end
