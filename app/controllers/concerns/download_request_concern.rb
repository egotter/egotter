require 'active_support/concern'

module DownloadRequestConcern
  extend ActiveSupport::Concern
  include ValidationConcern

  included do
    before_action(only: :download) { head :forbidden if twitter_dm_crawler? }
    before_action :valid_screen_name?, only: :download
    before_action(only: :download) { head :forbidden unless SearchRequest.request_for(current_user&.id, screen_name: params[:screen_name]) }
    before_action(only: :download) { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:screen_name]) }
  end

  private

  def filename_for_download
    "#{@twitter_user.screen_name}-#{controller_name}.csv"
  end

  def limit_for_download
    user_signed_in? && current_user.has_valid_subscription? ? Order::BASIC_PLAN_USERS_LIMIT : Order::FREE_PLAN_USERS_LIMIT
  end

  def data_for_download(users)
    CsvBuilder.new(users, with_description: user_signed_in? && current_user.has_valid_subscription?).build
  end

  def render_for_download(data)
    if request.device_type == :smartphone
      render plain: data
    else
      send_data data, filename: filename_for_download, type: 'text/csv; charset=utf-8'
    end
  end
end
