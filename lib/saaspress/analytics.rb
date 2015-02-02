module Saaspress
  # Provides Analytics.track_event and Tracker.track_traits to track events
  # and users in segment.io
  class Analytics

    def self.track_event(event_name, props={}, options={})
      options = {
        providers: %i{mixpanel},
        timestamp: Time.now,
      }.merge(options)

      props[:meta] ||= {}
      props[:meta].merge!(
        git_commit: ENV["GIT_COMMIT"],
        process_id: Process.pid,
        thread_id: Thread.current.object_id,
        hostname: Socket.gethostname,
        rails_env: ::Rails.env,
      )
      Saaspress::Jobs::TrackEventJob.perform_async(event_name, props, options)
    end

    # track_traits() tracks traits of a user. It's a thin wrapper around
    # segment io's identify: https://segment.io/libraries/ruby#identify
    #
    # For example, when a user's email changes, you can do
    # Analytics.track_traits("1234...", {email: "new_email@example.com"})
    def self.track_traits(analytics_id, traits, options={})
      options = {
        user_id: analytics_id,
        traits: traits,
        timestamp: Time.now,
        context: {}
      }.merge(options)

      options[:traits][:rails_env] = ::Rails.env

      if options[:user_id].blank?
        raise "user_id must be a non-blank value"
      end

      Saaspress::Jobs::TrackTraitsJob.perform_async(options)
    end
  end
end
