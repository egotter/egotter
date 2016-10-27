class PageCachesController < ApplicationController
  include Validation
  include SearchesHelper
  include PageCachesHelper

  layout false

  before_action(only: %i(create destroy)) { valid_uid?(params[:id].to_i) }
  before_action(only: %i(create destroy)) { existing_uid?(params[:id].to_i) }
  before_action(only: %i(create destroy)) { @searched_tw_user = TwitterUser.latest(params[:id].to_i) }

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

    if verity_page_cache_token(params[:hash], tu.created_at.to_i)
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
