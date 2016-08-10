class SearchResultsController < ApplicationController
  include Logging
  include SearchesHelper
  include PageCachesHelper

  layout false

  before_action :set_twitter_user, only: %i(show)

  def show
    tu = @searched_tw_user
    user_id = current_user_id

    save_twitter_user_to_cache(tu.uid, user_id, screen_name: tu.screen_name, user_info: tu.user_info)
    @job_id = add_background_search_worker_if_needed(tu.uid, user_id, screen_name: tu.screen_name)

    page_cache = PageCache.new(redis)
    if page_cache.exists?(tu.uid, user_id)
      html = page_cache.read(tu.uid, user_id)
    else
      create_instance_variables_for_result_page(tu)
      html = render_to_string(layout: false)
      page_cache.write(tu.uid, user_id, html)
    end

    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{user_id} #{request.device_type} #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
