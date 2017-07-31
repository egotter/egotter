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
    # Do nothing.
    head :ok
  end

  # DELETE /page_caches/:id
  def destroy
    # Do nothing.
    head :ok
  end
end
