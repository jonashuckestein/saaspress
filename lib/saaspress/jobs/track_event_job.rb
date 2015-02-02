# Tracks event across the three providers keen, mixpanel and intercom.
#
# `options` includes the list of providers to send the event to as well as
# the timestamp of when the event happened.
#
# Each provider modifies the data a little bit to fit their schema. See the
# methods track_keen, track_mixpanel and track_intercom respectively

module Saaspress
  module Jobs

    class TrackEventJob

      include Sidekiq::Worker
      sidekiq_options queue: :analytics

      def perform(event, props, options)

        options.symbolize_keys!

        options = {
          providers: %i{mixpanel},
          timestamp: Time.now.iso8601
        }.merge(options)

        if Saaspress.config.analytics_enabled
          logger.info "Tracking event #{event}"
          options[:providers].each do |provider|
            self.class.send("track_#{provider}", event, props.clone, options)
          end
        else
          logger.info "Not tracking event: #{event}"
          logger.debug props.inspect
        end

        #options["timestamp"] = options["timestamp"].present? ?
          #Time.parse(options["timestamp"]) : Time.now

        #if options["user_id"].blank?
          #raise "user_id must be a non-blank value"
        #elsif options["event"].blank?
          #raise "event must be a non-empty string"
        #elsif !options["timestamp"].is_a?(Time)
          #raise "timestamp must be an instance of Time"
        #end

      end

      def self.track_keen(event, props, options)
        if options[:timestamp].present?
          props[:keen] ||= {}
          props[:keen][:timestamp] ||= options[:timestamp]
        end
        Keen.publish(event, props)
      end

      def self.track_intercom(event, props, options)
        return # TODO use config.analytics_events_providers
        props = flatten_props(props)

        # in intercom we only track events if they belong to a user
        user_id = props["user.id"]

        return if user_id.nil?

        Intercom::Event.create(
          created_at: options[:timestamp].to_i,
          user_id: user_id,
          event_name: event,
          metadata: props
        )
      end

      def self.track_mixpanel(event, props, options)

        props = flatten_props(props)

        # In mixpanel we group events by account (that's how revenue is counted)
        distinct_id = props["meta.analytics_id"] || "N/A"

        # treatment of special mixpanel
        if props["request.remote_ip"]
          props["ip"] = props["request.remote_ip"]
        end
        if props["request.browser.user_agent"]
          props["$browser"] = props["request.browser.name"]
          props["$os"] = props["request.browser.platform"]
        end

        tracker = Mixpanel::Tracker.new(ENV["MIXPANEL_TOKEN"])

        tracker.track(distinct_id, event, props)
      end

      def self.flatten_props(props, prefix="", split=".")
        new_props = {}
        props.each do |key, val|
          if val.is_a?(Hash)
            new_props.merge!(flatten_props(val, "#{prefix}#{key}#{split}", split))
          else
            new_props["#{prefix}#{key}"] = val
          end
        end
        new_props
      end
    end
  end
end
