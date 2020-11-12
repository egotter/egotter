require 'active_support/concern'

module SearchReportConcern
  extend ActiveSupport::Concern
  include PeriodicReportConcern

  STOP_SEARCH_REPORT_REGEXP = /検索通知(\s|　)*停止/

  def stop_search_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(STOP_SEARCH_REPORT_REGEXP)
  end

  RESTART_SEARCH_REPORT_REGEXP = /検索通知(\s|　)*(再開|開始)/

  def restart_search_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(RESTART_SEARCH_REPORT_REGEXP)
  end

  def stop_search_report(dm)
    user = validate_periodic_report_status(dm.sender_id)
    return unless user

    StopSearchReportRequest.create(user_id: user.id)
    CreateSearchReportStoppedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def restart_search_report(dm)
    user = validate_periodic_report_status(dm.sender_id)
    return unless user

    StopSearchReportRequest.find_by(user_id: user.id)&.destroy
    CreateSearchReportRestartedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
