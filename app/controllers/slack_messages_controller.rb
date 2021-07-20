class SlackMessagesController < ApplicationController

  before_action :authenticate_admin!

  def index
    if params[:channel]
      query = SlackMessage.where(channel: params[:channel])
    else
      query = SlackMessage
    end
    @slack_messages = query.order(created_at: :desc).limit(300)
  end

  def show
    @slack_message = SlackMessage.find(params[:id])
  end
end
