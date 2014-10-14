module Saaspress
  module Models
    module SourceAttribution
      extend ActiveSupport::Concern

      # This is used when populating the utm_source field to group together
      # certain hosts
      REFERRING_HOSTS = {
        "facebook.com" => "facebook",
        "google.com" => "google",
        "bing.com" => "bing",
        "yahoo.com" => "yahoo",
        "googe.ca" => "google",
        "twitter.com" => "twitter",
        "t.co" => "twitter",
        "yc.com" => "ycombinator",
        "news.ycombinator.com" => "ycombinator",
        "blog.ycombinator.com" => "ycombinator",
        "ycombinator.com" => "ycombinator",
        "wired.com" => "wired",
        "pandodaily.com" => "pandodaily",
      }

      included do
        after_initialize :set_defaults
      end

      module ClassMethods
        #   direct: we have no referrer and no url params. no idea where user's from
        #   search: the referrer is a search engine
        #   organic: a non-search referrer links to us
        #   organic_social: link from twitter or facebook.
        #   paid: paid traffic. this has to be set using the url. if we used ad
        #         agencies, each agency would be a different medium
        #   press: if the referring host is on a list of press sites, we'll
        #          categorize them as press
        #   affiliate: if the visitor landed on an affiliate url. in that case,
        #              utm_campaign will be set to the affiliate campaign slug
        #   referral: if the user was referred by another user (not implemented)
        def get_utm_medium(request, attrs)
          if request.params[:utm_medium].present?
            return request.params[:utm_medium]
          end

          if request.referrer.nil?
            return "direct"
          end

          if attrs[:first_controller_action] == "affiliate_campaigns#visit"
            return "affiliate"
          end

          if attrs[:utm_source].in? %w{facebook twitter}
            return "organic social"
          elsif attrs[:utm_source].in? %w{google bing yahoo}
            return "organic search"
          elsif attrs[:utm_source].in? %w{wired pandodaily}
            return "press"
          end
        end

        def get_utm_source(request, attrs)
          if request.params[:utm_source].present?
            return request.params[:utm_source]
          else
            REFERRING_HOSTS[attrs[:referring_host]] || attrs[:referring_host]
          end
        end

        def get_host(url)
          if url.present?
            URI.parse(url).host
          else
            nil
          end
        rescue URI::InvalidURIError
          "parse error"
        end

        def get_country_code(request)
          request.headers["CF-IPCountry"] ||
            request.headers["CloudFront-Viewer-Country"] || "(unknown)"
        end

        def get_browser(http_user_agent)
          return {user_agent: nil} if http_user_agent.nil?
          user_agent = UserAgent.parse(http_user_agent)
          {
            user_agent: http_user_agent,
            name: user_agent.browser || "(unknown)",
            platform: user_agent.platform || "(unknown)",
            version: user_agent.version.to_s || "(unknown)",
          }
        end

        def init_attributes(request)
          attrs = {
            first_controller_action:
              "#{request.params[:controller]}##{request.params[:action]}",
            first_page_path: request.original_fullpath,
            first_seen_at: Time.now.iso8601,
            request_params: request.params,
            referring_url: request.referrer,
            referring_host: get_host(request.referrer),
            country_code: get_country_code(request),
            remote_ip: request.remote_ip,
            utm_terms: request.params[:utm_terms],
            utm_content: request.params[:utm_content],
            utm_campaign: request.params[:utm_campaign],
          }
          attrs[:browser] = get_browser(request.user_agent)
          attrs[:utm_source] = get_utm_source(request, attrs)
          attrs[:utm_medium] = get_utm_medium(request, attrs)
          if attrs[:utm_medium] == "affiliate"
            attrs[:utm_campaign] ||= request.params[:affiliate_slug]
          end
          puts "\n\nsource attribution: #{attrs.inspect}\n\n\n"
          attrs
        end
      end

      def analytics_traits
        attributes.except :created_at, :updated_at
      end

      # If, for whatever reason, source attribution is not in the session,
      # then some default values will be used
      def set_defaults
        self.utm_medium ||= "(missing source attribution)"
        self.first_page_path ||= "(missing source attribution)"
        self.first_controller_action ||= "(missing source attribution)"
        self.first_seen_at ||= Time.now
      end

      def first_seen_at=(datetime)
        datetime.respond_to?(:iso8601) ? super : Time.parse(datetime.to_s)
      end
    end
  end
end

