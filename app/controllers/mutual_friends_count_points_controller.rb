class MutualFriendsCountPointsController < ApplicationController
  include FriendsCountPointsConcern

  before_action :require_login!
  before_action { head :forbidden if request.referer.to_s.blank? }

  def download
    data = generate_csv(MutualFriendsCountPoint, params[:uid])
    send_data data, filename: 'mutual_friends.csv', type: 'text/csv; charset=utf-8'
  end
end
