require 'active_support/concern'

module Concerns::ApiRequestConcern
  extend ActiveSupport::Concern

  included do
    layout false

    # before_action -> { head :bad_request }, unless: -> { params[:token] }
    # skip_before_action :verify_authenticity_token

    before_action -> { valid_uid?(params[:uid]) }
    before_action -> { twitter_user_persisted?(params[:uid]) }
    before_action -> { twitter_db_user_persisted?(params[:uid]) }
    before_action -> { @twitter_user = TwitterUser.latest_by(uid: params[:uid]) }
    before_action -> { !protected_search?(@twitter_user) }
  end
end
