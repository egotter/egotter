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

  def via_periodic_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'periodic'
  end

  def via_search_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'search'
  end

  def via_block_report?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'block'
  end

  def via_welcome_message?
    params[:token].present? && %i(crawler UNKNOWN).exclude?(request.device_type) && params[:type] == 'welcome'
  end
end
