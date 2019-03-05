require 'active_support/concern'

module Concerns::AudienceInsights
  extend ActiveSupport::Concern

  included do
  end

  def find_or_create_chart_builder(twitter_user)
    Timeout.timeout(2.seconds) do
      AudienceInsight.find_by(uid: twitter_user.uid) || AudienceInsightChartBuilder.new(twitter_user.uid)
    end
  rescue Timeout::Error => e
    logger.info "#{controller_name}##{__method__} #{e.class} #{e.message} #{twitter_user.inspect}"
    logger.info e.backtrace.join("\n")
    nil
  end
end
