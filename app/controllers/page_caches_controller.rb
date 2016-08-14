class PageCachesController < ApplicationController
  include SearchesHelper
  include PageCachesHelper

  layout false

  before_action :set_twitter_user, only: %i(create destroy)

  # POST /page_caches
  def create
    tu = @searched_tw_user
    user_id = current_user_id

    create_instance_variables_for_result_page(tu)
    html = render_to_string(template: 'search_results/show')
    PageCache.new(redis).write(tu.uid, user_id, html)
    render nothing: true, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    render nothing: true, status: 500
  end

  # DELETE /page_caches/:id
  def destroy
    tu = @searched_tw_user
    user_id = current_user_id

    page_cache = PageCache.new(redis)
    if verity_delete_cache_token(params[:hash], tu.created_at.to_i)
      page_cache.delete(tu.uid, user_id)
      render nothing: true, status: 200
    else
      render nothing: true, status: 400
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    render nothing: true, status: 500
  end

  def clear
    return redirect_to '/' unless request.post?
    return redirect_to '/' unless current_user.admin?
    PageCache.new(redis).clear
    redirect_to '/'
  end
end
