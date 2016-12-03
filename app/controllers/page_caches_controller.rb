class PageCachesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper

  layout false

  skip_before_action :verify_authenticity_token, if: -> { action_name == 'create' && params[:token] == ENV['PAGE_CACHE_TOKEN'] }

  before_action(only: %i(create destroy)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(create destroy)) { existing_uid?(params[:uid].to_i) }
  before_action(only: %i(create destroy)) { @searched_tw_user = TwitterUser.latest(params[:uid].to_i) }

  before_action(only: %i(create destroy)) { create_page_cache_log(@searched_tw_user.uid, @searched_tw_user.screen_name, context: action_name) }

  # POST /page_caches
  def create
    tu = @searched_tw_user

    ::Cache::PageCache.new.write(tu.uid, render_to_string(template: 'search_results/show'))
    render nothing: true, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    render nothing: true, status: 500
  end

  # DELETE /page_caches/:id
  def destroy
    tu = @searched_tw_user

    if verify_page_cache_token(params[:hash], tu.created_at.to_i)
      ::Cache::PageCache.new.delete(tu.uid)
      render nothing: true, status: 200
    else
      render nothing: true, status: 400
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    render nothing: true, status: 500
  end
end
