# dependencies
require "user_agent"
require "keen"
require "intercom"
require "mixpanel-ruby"

require "saaspress/engine"

# SourceAttribution
require "saaspress/models/concerns/source_attribution"

# Analytics
# - requires SourceAttribution
require "saaspress/analytics"
require "saaspress/jobs/track_event_job"
require "saaspress/controllers/concerns/analytics"
require "saaspress/controllers/concerns/analytics_controller"

module Saaspress

  class << self
    # TODO fix config handling. This is just a quick hack because the
    # require reloader made it so that @config ||= ... didn't work
    def config
      $saaspress_config ||= Saaspress::Config.new
      #@config ||= Saaspress::Config.new
    end
  end

  class Config
    attr_accessor :analytics_enabled
    def initialize
      self.analytics_enabled = false
    end
  end

end
