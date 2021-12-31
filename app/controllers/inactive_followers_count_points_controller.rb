class InactiveFollowersCountPointsController < ApplicationController
  include FriendsCountPointsConcern

  before_action :require_login!
  before_action { head :forbidden if request.referer.to_s.blank? }

  def download
    data = generate_csv(InactiveFollowersCountPoint, params[:uid])
    send_data data, filename: 'inactive_followers.csv', type: 'text/csv; charset=utf-8'
  end
end
