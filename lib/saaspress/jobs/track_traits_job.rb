class Analytics::TrackTraitsJob
  include Sidekiq::Worker
  sidekiq_options queue: :analytics

  def perform(options)
    options["timestamp"] = options["timestamp"].present? ?
      Time.parse(options["timestamp"]) : Time.now

    if options["user_id"].blank?
      raise "user_id must be a non-blank value"
    elsif !options["timestamp"].is_a?(Time)
      raise "timestamp must be an instance of Time"
    end

    if Saaspress.config.analytics_enabled
      AnalyticsRuby.identify(options)
      logger.info "Tracked traits for #{options["user_id"]}"
    else
      logger.info "Not tracking traits for #{options["user_id"]}"
      logger.debug options.inspect
    end
  end
end
