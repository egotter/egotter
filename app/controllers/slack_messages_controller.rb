class SlackMessagesController < ApplicationController

  before_action :authenticate_admin!

  def index
    @slack_messages = SlackMessage.order(created_at: :desc).limit(100)
  end

  def show
    @slack_message = SlackMessage.find(params[:id])
  end
end
