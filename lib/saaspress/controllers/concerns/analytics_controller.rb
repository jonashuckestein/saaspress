# Only works if the analytics concern is mixed into the application
# controller
# To use this, we need to create an analytics_controller in the rails app
# that includes this concern and add a route:
#  post "analytics/track_event" => "analytics#track", as: "track_event"
module Saaspress
  module Controllers
    module AnalyticsController
      extend ActiveSupport::Concern

      def track
        raise "Event name is required" if params[:event_name].nil?
        properties = params[:properties] || {}

        # The google bot executes javascript and ajax calls
        if is_robot? && robot_name != "Googlebot"
          rollbar_warning("POST analytics/track_event called for event '#{params[:event_name]}' but is_robot? is true. Possible false positive categorization for user agent '#{request.user_agent}' as '#{robot_name}'")
        end

        track_event(params[:event_name], properties)
        render json: {success: true}
      end
    end
  end
end

