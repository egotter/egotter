class SearchResultsController < ApplicationController
  include Validation
  include Concerns::Logging
  include PageCachesHelper
  include TweetTextHelper
  include SearchesHelper

  layout false

  before_action :need_login, only: %i(common_friends common_followers)
  before_action(only: Search::MENU) { valid_uid?(params[:uid].to_i) }
  before_action(only: Search::MENU) { existing_uid?(params[:uid].to_i) }
  before_action(only: Search::MENU) { @searched_tw_user = TwitterUser.latest(params[:uid].to_i) }
  before_action(only: Search::MENU) { authorized_search?(@searched_tw_user) }

  %i(favoriting).each do |menu|
    define_method(menu) do
      begin
        uids = @searched_tw_user.favorite_friendships.pluck(:friend_uid)
        users = TwitterDB::User.where(uid: uids).index_by(&:uid)
        users = uids.map { |uid| users[uid] }.compact

        @graph = chart_for(users.size, users.size * 2, menu)
        @tweet_text = close_friends_text(users, @searched_tw_user)
        @user_items = TwitterUsersDecorator.new(users).items
        render json: {html: render_to_string(template: 'search_results/common', locals: {menu: menu})}, status: 200
      rescue => e
        logger.warn "#{self.class}##{menu}: #{e.class} #{e.message} #{current_user_id} #{@searched_tw_user.uid} #{@searched_tw_user.screen_name} #{client.access_token} #{request.device_type} #{request.browser}"
        logger.info e.backtrace.grep_v(/\.bundle/).empty? ? e.backtrace.join("\n") : e.backtrace.grep_v(/\.bundle/).join("\n")
        render nothing: true, status: 500
      end
    end
  end

  def usage_stats
    head :not_found
  end

  def close_friends
    head :not_found
  end
end
