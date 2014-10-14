### Analytics (segment.io et al) ###
#
# Usage: call track_event with an event_name and some properties anywhere
# in a controller and the right thing will happen.
#
# If the user isn't logged in yet, we use values from the session to
# identify the user and track where they came from.
#
# Include in ApplicationController using `include Analytics`
#
# Requires
#   - SourceAttribution
#   - current_user (i.e. devise)
#   - current.user.account.analytics_id and current_user.account.analytics_traits
#
# TODO
#   - add convenience class level methods to skip event tracking
module Saaspress
  module Controllers
    module Analytics
      extend ActiveSupport::Concern

      # taken from https://github.com/andrew/split/blob/c17dcc2a4252ad56844c3077eac760401963e46e/lib/split/configuration.rb
      BOTS = {
        # Indexers
        'AdsBot-Google' => 'Google Adwords',
        'Baidu' => 'Chinese search engine',
        'Baiduspider' => 'Chinese search engine',
        'bingbot' => 'Microsoft bing bot',
        'Butterfly' => 'Topsy Labs',
        'Gigabot' => 'Gigabot spider',
        'Googlebot' => 'Googlebot',
        'MJ12bot' => 'Majestic-12 spider',
        'msnbot' => 'Microsoft bot',
        'rogerbot' => 'SeoMoz spider',
        'PaperLiBot' => 'PaperLi is another content curation service',
        'Slurp' => 'Yahoo spider',
        'Sogou' => 'Chinese search engine',
        'spider' => 'generic web spider',
        'UnwindFetchor' => 'Gnip crawler',
        'WordPress' => 'WordPress spider',
        'YandexBot' => 'Yandex spider',
        'ZIBB' => 'ZIBB spider',

        # HTTP libraries
        'Apache-HttpClient' => 'Java http library',
        'AppEngine-Google' => 'Google App Engine',
        'curl' => 'curl unix CLI http client',
        'ColdFusion' => 'ColdFusion http library',
        'EventMachine HttpClient' => 'Ruby http library',
        'Go http package' => 'Go http library',
        'Java' => 'Generic Java http library',
        'libwww-perl' => 'Perl client-server library loved by script kids',
        'lwp-trivial' => 'Another Perl library loved by script kids',
        'Python-urllib' => 'Python http library',
        'PycURL' => 'Python http library',
        'Test Certificate Info' => 'C http library?',
        'Wget' => 'wget unix CLI http client',

        # URL expanders / previewers
        'awe.sm' => 'Awe.sm URL expander',
        'bitlybot' => 'bit.ly bot',
        'bot@linkfluence.net' => 'Linkfluence bot',
        'facebookexternalhit' => 'facebook bot',
        'Feedfetcher-Google' => 'Google Feedfetcher',
        'https://developers.google.com/+/web/snippet' => 'Google+ Snippet Fetcher',
        'LongURL' => 'URL expander service',
        'NING' => 'NING - Yet Another Twitter Swarmer',
        'redditbot' => 'Reddit Bot',
        'ShortLinkTranslate' => 'Link shortener',
        'TweetmemeBot' => 'TweetMeMe Crawler',
        'Twitterbot' => 'Twitter URL expander',
        'UnwindFetch' => 'Gnip URL expander',
        'vkShare' => 'VKontake Sharer',

        # Uptime monitoring
        'check_http' => 'Nagios monitor',
        'NewRelicPinger' => 'NewRelic monitor',
        'Panopta' => 'Monitoring service',
        'Pingdom' => 'Pingdom monitoring',
        'SiteUptime' => 'Site monitoring services',

        # ???
        'DigitalPersona Fingerprint Software' => 'HP Fingerprint scanner',
        'ShowyouBot' => 'Showyou iOS app spider',
        'ZyBorg' => 'Zyborg? Hmmm....',
      }

      def self.robot_regex
        return @_robot_regex if @_robot_regex.present?
        escaped_bots = BOTS.map { |key, _| Regexp.escape(key) }
        @_robot_regex = /\b(?:#{escaped_bots.join("|")})\b|\A\W*\z/i
      end

      included do
        # Each visitor gets a unique id as soon as they hit the site.
        # This id is used e.g. when placing holds on phone numbers
        before_action :create_analytics_info
        around_action :track_request
        helper_method :analytics_id
        helper_method :analytics_traits
        helper_method :is_robot?
        helper_method :bot_name?
      end

      # Tracks an event. `options` allows you to override parameters
      # in the segmentio call but it is usually not needed.
      #
      # Example call: track_event("Requested url", {url: "..."})
      #
      # `track_event` automatically pulls in all properties in
      # analytics_traits, so you don't have to
      def track_event(event, props={}, options={}, force=false)

        # no events are tracked in response to robot visits unless specifically
        # requested (i.e. in the errors controller or the http request event)
        return false if is_robot? && !force

        # add analytics traits, most importantly the user and account properties
        props.merge!(analytics_traits)

        Saaspress::Analytics.track_event(event, props, options)
      end

      # The `analytics_id` is used throughout to identify a visitor consistently,
      # even after they sign up
      def analytics_id
        current_user.present? ? current_user.account.analytics_id : session[:analytics_id]
      end

      # create_analytics_info is run the first time a visitor hits the server
      # (unless they're a robot)
      #
      # It populates the following fields in the session
      #  - analytics_id
      #  - source_attribution
      #
      # Also tracks the first seen event
      #
      # TODO consider updating utm_* props on subequent visit if present
      # TODO what happens if the visitor doesn't have cookies enabled?

      def create_analytics_info
        return if analytics_id.present? || is_robot?

        session[:analytics_id] = SecureRandom.uuid
        session[:source_attribution] = SourceAttribution.init_attributes(request)

        track_event("First seen")
      end

      # Returns the analytics traits that are attached to each event
      # (in addition to the event properties)
      def analytics_traits
        if user_signed_in?
          traits = {
            meta: {
              analytics_id: current_user.account.analytics_id,
              signed_up: true,
            },
            user: current_user.analytics_traits,
            account: current_user.account.analytics_traits,
          }
        else
          traits = {
            meta: {
              analytics_id: analytics_id,
              signed_up: false,
            },
            account: {
              source_attribution: session[:source_attribution],
            }
          }
        end

        traits[:request] ||= {}

        traits[:request].merge!(
          path: request.original_fullpath,
          method: request.method,
          remote_ip: request.remote_ip,
          country_code: request_country_code,
          referrer: request.referrer,
          is_robot: is_robot?,
        )
        if is_robot?
          traits[:request][:robot] = { name: robot_name }
        end

        traits[:request][:browser] ||= {}
        traits[:request][:browser].merge!(
          SourceAttribution.get_browser(request.user_agent))

        traits
      end

      # After each request, a "Requested url" event is fired (even in the case
      # of errors or redirects). This makes it very easy to debug issues a
      # user is having
      def track_request
        response_time = Benchmark.realtime { yield }

        event_name = "HTTP request"

        props = {
          response: {
            status: response.status,
            status_text: response.message,
            redirect_url: response.location,
            render_time_in_ms: (response_time*1000).floor,
          }
        }
        track_event(event_name, props, {providers: %w{keen}}, true)
      end

      def is_robot?
        if @_is_robot.nil?
          @_is_robot = !!(request.user_agent =~ Analytics.robot_regex)
        end
        @_is_robot
      end

      def robot_name
        return nil unless is_robot?
        Analytics::BOTS.each do |regex, bot|
          return bot if request.user_agent =~ /\b(?:#{Regexp.escape(regex)})\b/i
        end
        return "(unknown)"
      end

      # determine the country code based on our CDN country header
      def request_country_code
        SourceAttribution.get_country_code(request)
      end

    end
  end
end
