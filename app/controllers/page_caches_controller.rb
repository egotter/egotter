class PageCachesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper

  layout false

  skip_before_action :verify_authenticity_token, if: -> { action_name == 'create' && params[:token] == ENV['PAGE_CACHE_CREATE_TOKEN'] }
  skip_before_action :verify_authenticity_token, if: -> { action_name == 'destroy' && request.referer.starts_with?('https://egotter.com') }

  before_action(only: %i(create destroy)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(create destroy)) { existing_uid?(params[:uid].to_i) }
  before_action(only: %i(create destroy)) { @twitter_user = TwitterUser.latest(params[:uid].to_i) }

  before_action(only: %i(create destroy)) { create_page_cache_log(action_name) }

  def create
    @searched_tw_user = @twitter_user # for search_results/show
    ::Cache::PageCache.new.write(@twitter_user.uid, render_to_string(template: 'search_results/show'))
    head :ok
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{@twitter_user.uid} #{@twitter_user.screen_name} #{request.browser}"
    head :internal_server_error
  end

  # DELETE /page_caches/:id
  def destroy
    ::Cache::PageCache.new.delete(@twitter_user.uid)
    head :ok
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{@twitter_user.uid} #{@twitter_user.screen_name} #{request.browser}"
    head :internal_server_error
  end
end
