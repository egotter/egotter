require 'active_support/concern'

module NewrelicConcern
  extend ActiveSupport::Concern

  def disable_newrelic_tracer_for_crawlers
    if twitter_dm_crawler?
      NewRelic::Agent.disable_all_tracing do
        yield
      end
    else
      yield
    end
  end
end
