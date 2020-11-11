require 'active_support/concern'

module PeriodicReportConcern
  extend ActiveSupport::Concern

  SEND_PERIODIC_REPORT_REGEXP = /((リム|りむ)(られた?)?通知)|今すぐ(送信)?/

  def send_periodic_report_requested?(text)
    text.length <= 15 && text.match?(SEND_PERIODIC_REPORT_REGEXP)
  end

  module_function :send_periodic_report_requested?

  CONTINUE_PERIODIC_REPORT_REGEXP = /継続|断続|けいぞく|復活|再会/

  def continue_periodic_report_requested?(text)
    text.length < 15 && text.match?(CONTINUE_PERIODIC_REPORT_REGEXP)
  end

  module_function :continue_periodic_report_requested?

  STOP_PERIODIC_REPORT_REGEXP = /【?リム(られ)?通知(\s|　)*(停止|ていし)】?/

  def stop_periodic_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(STOP_PERIODIC_REPORT_REGEXP)
  end

  RESTART_PERIODIC_REPORT_REGEXP = /リム(られ)?通知(\s|　)*(再開|さいかい|再会|復活|ふっかつ)/

  def restart_periodic_report_requested?(dm)
    dm.text.length < 15 && dm.text.match?(RESTART_PERIODIC_REPORT_REGEXP)
  end

  RECEIVED_REGEXP = /リム(られ)?通知(\s|　)*届きました/

  def periodic_report_received?(dm)
    dm.text.length < 15 && dm.text.match?(RECEIVED_REGEXP)
  end

  def enqueue_user_requested_periodic_report(dm)
    user = validate_periodic_report_status(dm.sender_id)
    return unless user

    DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

    unless user.has_valid_subscription?
      unless EgotterFollower.exists?(uid: user.uid)
        CreatePeriodicReportNotFollowingMessageWorker.perform_async(user.id)
        return
      end

      if PeriodicReport.interval_too_short?(user)
        CreatePeriodicReportIntervalTooShortMessageWorker.perform_async(user.id)
        return
      end

      if PeriodicReport.access_interval_too_long?(user)
        CreatePeriodicReportAccessIntervalTooLongMessageWorker.perform_async(user.id)
        return
      end
    end

    request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'user')
    CreateUserRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_egotter_requested_periodic_report(dm)
    user = validate_periodic_report_status(dm.recipient_id)
    return unless user

    request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'egotter')
    CreateEgotterRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def stop_periodic_report(uid)
    user = validate_periodic_report_status(uid)
    return unless user

    DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

    StopPeriodicReportRequest.create(user_id: user.id)
    CreatePeriodicReportStopRequestedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end

  def restart_periodic_report(uid)
    user = validate_periodic_report_status(uid)
    return unless user

    DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

    StopPeriodicReportRequest.find_by(user_id: user.id)&.destroy
    CreatePeriodicReportRestartRequestedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end

  def continue_periodic_report(uid)
    user = validate_periodic_report_status(uid)
    return unless user

    DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

    CreatePeriodicReportContinueRequestedMessageWorker.perform_async(user.id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end

  private

  def validate_periodic_report_status(uid)
    unless (user = User.find_by(uid: uid))
      CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: uid)
      return
    end

    unless user.authorized?
      CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
      return
    end

    unless user.notification_setting.enough_permission_level?
      CreatePeriodicReportMessageWorker.perform_async(user.id, permission_level_not_enough: true)
      return
    end

    user
  end
end
