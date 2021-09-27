class SlackMessagesController < ApplicationController

  before_action :authenticate_admin!

  def index
    if params[:channel]
      query = SlackMessage.where(channel: params[:channel].split(','))
      @channel = params[:channel] unless params[:channel].include?(',')
    else
      query = SlackMessage
    end

    slack_messages = query.order(created_at: :desc).limit(300)
    @slack_messages_groups = slack_messages.group_by { |m| m.created_at.in_time_zone('Tokyo').strftime('%-m/%d') }
  end

  def show
    @slack_message = SlackMessage.find(params[:id])
  end
end
