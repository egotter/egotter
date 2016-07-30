class SearchResultsController < ApplicationController
  include MenuItemBuilder
  include Logging
  include SearchesHelper
  include PageCachesHelper

  before_action :set_twitter_user, only: %i(show)

  def show
    tu = @searched_tw_user
    user_id = current_user_id

    add_background_search_worker_if_needed(tu.uid, tu.screen_name, tu.user_info, request)

    page_cache = PageCache.new(redis)
    if page_cache.exists?(tu.uid, user_id)
      html = page_cache.read(tu.uid, user_id)
      logger.info "#{self.class}##{__method__}: A page cache is loaded. #{tu.uid} #{user_id}" # TODO remove debug code
    else
      create_instance_variables_for_result_page(tu)
      html = render_to_string(layout: false)
      page_cache.write(tu.uid, user_id, html)
      logger.info "#{self.class}##{__method__}: A page cache is created. #{tu.uid} #{user_id}" # TODO remove debug code
    end

    render json: {status: 200, html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render json: {status: 500}, status: 500
  end
end
