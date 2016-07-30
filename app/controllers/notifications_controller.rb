class NotificationsController < ApplicationController
  include Logging
  include SearchesHelper

  before_action only: %i(index) do
    create_search_log(action: :notifications)
  end

  def index
    redirect_to '/' unless user_signed_in?

    @title = t('dictionary.bell')
    @items = TwitterUser.all.limit(3).map.with_index { |tu, i| Hashie::Mash.new({user: tu, message: i.to_s * 3}) }
  end
end
