module Api
  class Base < ApplicationController
    include SearchesHelper
    include Validation

    layout false

    # before_action -> { head :bad_request }, unless: -> { params[:token] }
    # skip_before_action :verify_authenticity_token

    before_action -> { valid_uid?(params[:uid].to_i) }
    before_action -> { existing_uid?(params[:uid].to_i) }
    before_action -> { @twitter_user = TwitterUser.latest(params[:uid].to_i) }
    before_action -> { authorized_search?(@twitter_user) }

    def summary
      limit = 3
      uids = summary_uids
      users = TwitterDB::User.where(uid: uids.take(limit)).index_by(&:uid)
      users = uids.take(limit).map { |uid| users[uid] }.compact.map do |u|
        Hashie::Mash.new({uid: u.uid.to_s, screen_name: u.screen_name, profile_image_url_https: u.profile_image_url_https.to_s})
      end

      render json: {name: controller_name, count: uids.size, users: users}, status: 200
    end
  end
end