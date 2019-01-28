class UnfollowController < ApplicationController
  include WorkersHelper

  before_action :reject_crawler
  before_action :require_login!

  def create
    user = current_user
    request = UnfollowRequest.new(user_id: user.id, uid: params[:uid])
    if request.save
      enqueue_create_unfollow_job_if_needed(user.id)

      render json: {
          unfollow_request_id: request.id,
          can_create_unfollow: user.can_create_unfollow?,
          create_unfollow_limit: user.create_unfollow_limit
      }
    else
      logger.warn "#{controller_name}##{action_name} #{request.errors.full_messages}"
      head :unprocessable_entity
    end
  end
end
