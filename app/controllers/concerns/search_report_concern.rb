require 'active_support/concern'

module SearchReportConcern
  extend ActiveSupport::Concern

  STOP_SEARCH_REPORT_REGEXP = /検索通知(\s|　)*停止/

  def stop_search_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(STOP_SEARCH_REPORT_REGEXP)
  end

  RESTART_SEARCH_REPORT_REGEXP = /検索通知(\s|　)*再開/

  def restart_search_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(RESTART_SEARCH_REPORT_REGEXP)
  end

  def process_stopping_search_report(dm)
    unless (user = User.where(authorized: true).find_by(uid: dm.sender_id))
      return
    end

    unless (request = StopSearchReportRequest.find_by(user_id: user.id))
      request = StopSearchReportRequest.create(user_id: user.id)
    end

    CreateSearchReportStoppedMessageWorker.perform_async(user.id, request_id: request.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def process_restarting_search_report(dm)
    unless (user = User.where(authorized: true).find_by(uid: dm.sender_id))
      return
    end

    if (request = StopSearchReportRequest.find_by(user_id: user.id))
      request.destroy
    end

    CreateSearchReportRestartedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
