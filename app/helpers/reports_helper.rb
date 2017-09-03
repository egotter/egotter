module ReportsHelper
  def via_dm?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:medium] == 'dm'
  end

  def via_onesignal?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:medium] == 'onesignal'
  end

  def via_notification?
    via_dm? || via_onesignal?
  end

  def via_prompt_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'prompt'
  end

  def via_search_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'search'
  end

  def via_news_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'news'
  end
end
