class CachesController < ApplicationController
  include CachesHelper
  include SearchesHelper

  before_action :set_twitter_user, only: %i(destroy)

  def destroy
    tu = @searched_tw_user
    user_id = current_user_id

    page_cache = PageCache.new(redis)
    if params.has_key?(:hash) && params[:hash].match(/\A[0-9a-zA-Z]{20}\z/)[0] == update_hash(tu.created_at.to_i)
      page_cache.delete(tu.uid, user_id)
      render json: {status: 200}, status: 200
    else
      render json: {status: 400, reason: t('before_sign_in.that_page_doesnt_exist')}, status: 400
    end
  end
end
