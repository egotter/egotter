require 'active_support/concern'

module PeriodicReportConcern
  extend ActiveSupport::Concern

  SEND_NOW_REGEXP = /【?(リム(られ)?通知)?(\s|　)*(今すぐ|いますぐ)(送信|そうしん|受信|じゅしん|痩身|通知|返信|配信|はいしん|更新|こうしん)】?/

  def send_now_requested?(dm)
    dm.text.match?(SEND_NOW_REGEXP)
  end

  SEND_NOW_EXACTLY_REGEXP = /\Aリムられ通知 今すぐ送信\z/

  def send_now_exactly_requested?(dm)
    dm.text.match?(SEND_NOW_EXACTLY_REGEXP)
  end

  CONTINUE_WORDS = [
      '継続',
      'けいぞく',
      '再開',
      '復活',
      '届いてません',
      'フォローしました',
      'フォローしたよ',
      'テスト送信 届きました',
      '初期設定 届きました',
      '通知がきません',
      '更新して',
      '早くしろよ',
      'まだですか',
      'ぴえん'
  ]
  CONTINUE_REGEXP = Regexp.union(CONTINUE_WORDS)
  CONTINUE_FUZZY_REGEXP = /\A(あー?|リムられ通知)\z/
  CONTINUE_EXACT_REGEXP = /【?リム(られ)?通知(\s|　)*継続】?/

  def continue_requested?(dm)
    dm.text.match?(CONTINUE_REGEXP) || dm.text.match?(CONTINUE_FUZZY_REGEXP)
  end

  STOP_NOW_REGEXP = /【?リム(られ)?通知(\s|　)*(停止|ていし)】?/

  def stop_now_requested?(dm)
    dm.text.match?(STOP_NOW_REGEXP)
  end

  STOP_NOW_EXACTLY_REGEXP = /\Aリムられ通知 停止\z/

  def stop_now_exactly_requested?(dm)
    dm.text.match?(STOP_NOW_EXACTLY_REGEXP)
  end

  RESTART_REGEXP = /【?リム(られ)?通知(\s|　)*(再開|さいかい|再会|復活|ふっかつ)】?/

  def restart_requested?(dm)
    dm.text.match?(RESTART_REGEXP)
  end

  RESTART_EXACTLY_REGEXP = /\Aリムられ通知 再開\z/

  def restart_exactly_requested?(dm)
    dm.text.match?(RESTART_EXACTLY_REGEXP)
  end

  RECEIVED_REGEXP = /\Aリム(られ)?通知(\s|　)*届きました\z/

  def report_received?(dm)
    dm.text.match?(RECEIVED_REGEXP)
  end

  def enqueue_user_requested_periodic_report(dm, fuzzy: false)
    unless (user = User.find_by(uid: dm.sender_id))
      CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: dm.sender_id)
      return
    end

    DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

    if user.authorized?
      if !fuzzy || CreatePeriodicReportRequest.sufficient_interval?(user.id)
        request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'user')
        CreateUserRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
      end
    elsif !user.notification_setting.enough_permission_level?
      CreatePeriodicReportMessageWorker.perform_async(user.id, permission_level_not_enough: true)
    else
      CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
    end

  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_user_received_periodic_report(dm)
    if (user = User.find_by(uid: dm.sender_id)) && user.authorized? &&
        CreatePeriodicReportRequest.sufficient_interval?(user.id) &&
        EgotterFollower.exists?(uid: user.uid)
      DeleteRemindPeriodicReportRequestWorker.perform_async(user.id)

      request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'user')
      CreateUserRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
    end

  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_user_requested_stopping_periodic_report(dm)
    stop_periodic_report(dm.sender_id)
  end

  def enqueue_user_requested_restarting_periodic_report(dm)
    restart_periodic_report(dm.sender_id)
  end

  def enqueue_egotter_requested_periodic_report(dm)
    unless (user = User.find_by(uid: dm.recipient_id))
      CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: dm.recipient_id)
      return
    end

    if user.authorized?
      request = CreatePeriodicReportRequest.create(user_id: user.id, requested_by: 'egotter')
      CreateEgotterRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id)
    elsif !user.notification_setting.enough_permission_level?
      CreatePeriodicReportMessageWorker.perform_async(user.id, permission_level_not_enough: true)
    else
      CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
    end

  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_egotter_requested_stopping_periodic_report(dm)
    stop_periodic_report(dm.recipient_id)
  end

  def enqueue_egotter_requested_restarting_periodic_report(dm)
    restart_periodic_report(dm.recipient_id)
  end

  private

  def stop_periodic_report(uid)
    if (user = User.find_by(uid: uid))
      StopPeriodicReportRequest.create(user_id: user.id) # If the same record exists, this process may fail
      CreatePeriodicReportStopRequestedMessageWorker.perform_async(user.id)
    end
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end

  def restart_periodic_report(uid)
    if (user = User.find_by(uid: uid))
      StopPeriodicReportRequest.find_by(user_id: user.id)&.destroy
      CreatePeriodicReportMessageWorker.perform_async(user.id, restart_requested: true)
    end
  rescue => e
    logger.warn "##{__method__} #{e.inspect} uid=#{uid}"
  end
end
