class PageCachesController < ApplicationController
  include Validation
  include SearchesHelper
  include PageCachesHelper

  layout false

  before_action(only: %i(create destroy)) { valid_uid?(params[:id].to_i) }
  before_action(only: %i(create destroy)) { existing_uid?(params[:id].to_i) }
  before_action(only: %i(create destroy)) { @searched_tw_user = fetch_twitter_user_with_client(params[:id].to_i) }

  # POST /page_caches
  def create
    tu = @searched_tw_user

    create_instance_variables_for_result_page(tu, login_user: User.find_by(id: current_user_id))
    PageCache.new(redis).write(tu.uid, render_to_string(template: 'search_results/show'))
    render nothing: true, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    render nothing: true, status: 500
  end

  # DELETE /page_caches/:id
  def destroy
    tu = @searched_tw_user

    if verity_page_cache_token(params[:hash], tu.created_at.to_i)
      PageCache.new(redis).delete(tu.uid)
      render nothing: true, status: 200
    else
      render nothing: true, status: 400
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{tu.inspect}"
    render nothing: true, status: 500
  end

  def clear
    return redirect_to root_path unless request.post?
    return redirect_to root_path unless current_user.admin?
    PageCache.new(redis).clear
    redirect_to root_path
  end
end
