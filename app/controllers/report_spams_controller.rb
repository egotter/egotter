class ReportSpamsController < ApplicationController
  before_action :reject_crawler
  before_action :require_login!
  before_action(only: :create) { valid_uid?(params[:uid]) }

  before_action do
    if action_name == 'create'
      create_search_log(uid: params[:uid])
    else
      create_search_log
    end
  end

  def create
    uid = params[:uid].to_i
    request_context_client.report_spam(user_id: [uid])
    render json: {uid: uid, report_spam: true, message: t('.success', user: fetch_screen_name(uid))}
  rescue => e
    render json: {uid: uid, report_spam: true, message: t('.failed', user: fetch_screen_name(uid)), error_class: e.class, error_message: e.message}, status: :bad_request
  end

  private

  def fetch_screen_name(uid)
    request_context_client.user(uid)
  rescue => e
    uid
  end
end
