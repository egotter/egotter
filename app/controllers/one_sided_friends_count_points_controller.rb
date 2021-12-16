class OneSidedFriendsCountPointsController < ApplicationController
  include FriendsCountPointsConcern

  before_action :require_login!
  before_action { head :forbidden if request.referer.to_s.blank? }

  def download
    data = generate_csv(OneSidedFriendsCountPoint, params[:uid])

    if request.device_type == :smartphone
      render plain: data
    else
      send_data data, filename: 'one_sided_friends.csv', type: 'text/csv; charset=utf-8'
    end
  end
end
