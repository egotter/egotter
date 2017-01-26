class OneSidedFollowersController < ApplicationController
  include Concerns::Logging

  before_action only: %i(new) do
    push_referer
    create_search_log(action: "#{controller_name}/#{action_name}")
  end

  def new
    @title = t('one_sided_followers.new.plain_title')
    render template: 'one_sided_friends/new'
  end
end
