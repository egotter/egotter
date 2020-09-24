require 'active_support/concern'

module ApiRequestConcern
  extend ActiveSupport::Concern

  included do
    layout false

    # skip_before_action :verify_authenticity_token
    before_action { head :forbidden unless request.headers['HTTP_X_CSRF_TOKEN'] }

    before_action -> { valid_uid?(params[:uid]) }
    before_action -> { twitter_db_user_persisted?(params[:uid]) }
    before_action -> { twitter_user_persisted?(params[:uid]) }
    before_action -> { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }
    before_action -> { !protected_search?(@twitter_user) }
  end
end
