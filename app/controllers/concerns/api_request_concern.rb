require 'active_support/concern'

module ApiRequestConcern
  extend ActiveSupport::Concern

  included do
    layout false

    # skip_before_action :verify_authenticity_token
    before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

    before_action { valid_uid?(params[:uid]) }
    before_action { head :forbidden unless SearchRequest.request_for(current_user&.id, uid: params[:uid]) }
    before_action { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }
  end
end
