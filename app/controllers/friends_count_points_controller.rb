class FriendsCountPointsController < ApplicationController
  include FriendsCountPointsConcern

  before_action :require_login!
  before_action { head :forbidden if request.referer.to_s.blank? }

  def download
    data = generate_csv(FriendsCountPoint, params[:uid])
    send_data data, filename: 'friends.csv', type: 'text/csv; charset=utf-8'
  end
end
