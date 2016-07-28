class PageCachesController < ApplicationController
  include SearchesHelper
  include MenuItemBuilder
  include PageCachesHelper

  before_action :set_twitter_user, only: %i(create destroy)

  # POST /page_caches
  def create
    tu = @searched_tw_user
    user_id = current_user_id

    create_instance_variables_for_result_page(tu)
    html = render_to_string(template: 'search_results/show', layout: false)
    PageCache.new(redis).write(tu.uid, user_id, html)
    logger.warn "#{self.class}##{__method__}: A page cache is created. #{tu.uid} #{user_id}" # TODO remove debug code
    render json: {status: 200}, status: 200

  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render json: {status: 500}, status: 500
  end

  # DELETE /page_caches/:id
  def destroy
    tu = @searched_tw_user
    user_id = current_user_id

    page_cache = PageCache.new(redis)
    if params.has_key?(:hash) && params[:hash].match(/\A[0-9a-zA-Z]{20}\z/)[0] == delete_cache_token(tu.created_at.to_i)
      page_cache.delete(tu.uid, user_id)
      logger.warn "#{self.class}##{__method__}: A page cache is deleted. #{tu.uid} #{user_id}" # TODO remove debug code
      render json: {status: 200}, status: 200
    else
      render json: {status: 400, reason: t('before_sign_in.that_page_doesnt_exist')}, status: 400
    end

  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render json: {status: 500}, status: 500
  end
end
