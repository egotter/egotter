require 'active_support/concern'

module Concerns::PeriodicReportConcern
  extend ActiveSupport::Concern

  SEND_NOW_REGEXP = /(今すぐ|いますぐ)(送信|そうしん|受信|じゅしん|痩身|通知|返信)/

  def send_now_requested?(dm)
    dm.text.match?(SEND_NOW_REGEXP)
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
      '早くしろよ',
      'まだですか',
      'ぴえん'
  ]
  CONTINUE_REGEXP = Regexp.union(CONTINUE_WORDS)

  def continue_requested?(dm)
    dm.text.match?(CONTINUE_REGEXP)
  end

  STOP_NOW_REGEXP = /(今すぐ|いますぐ)(停止|ていし)/

  def stop_now_requested?(dm)
    dm.text.match?(STOP_NOW_REGEXP)
  end

  RESTART_REGEXP = /リムられ通知(\s|　)*(再開|さいかい)/

  def restart_requested?(dm)
    dm.text.match?(RESTART_REGEXP)
  end

  def enqueue_user_requested_periodic_report(dm)
    if !send_now_requested?(dm) && !continue_requested?(dm)
      return
    end

    user = User.find_by(uid: dm.sender_id)
    unless user
      CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: dm.sender_id)
      return
    end

    if user.authorized?
      request = CreatePeriodicReportRequest.create(user_id: user.id)
      CreateUserRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id, create_twitter_user: true)
    elsif !user.notification_setting.enough_permission_level?
      CreatePeriodicReportMessageWorker.perform_async(user.id, permission_level_not_enough: true)
    else
      CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
    end

  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_user_requested_stopping_periodic_report(dm)
    return unless stop_now_requested?(dm)
    if (user = User.find_by(uid: dm.sender_id))
      StopPeriodicReportRequest.create(user_id: user.id) # If the same record exists, this process may fail
    end
    CreatePeriodicReportMessageWorker.perform_async(nil, stop_requested: true, uid: dm.sender_id)
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_user_requested_restarting_periodic_report(dm)
    return unless restart_requested?(dm)
    if (user = User.find_by(uid: dm.sender_id))
      StopPeriodicReportRequest.find_by(user_id: user.id)&.destroy
    end
  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end

  def enqueue_egotter_requested_periodic_report(dm)
    unless send_now_requested?(dm)
      return
    end

    user = User.find_by(uid: dm.recipient_id)
    unless user
      CreatePeriodicReportMessageWorker.perform_async(nil, unregistered: true, uid: dm.recipient_id)
      return
    end

    if user.authorized?
      request = CreatePeriodicReportRequest.create(user_id: user.id)
      CreateEgotterRequestedPeriodicReportWorker.perform_async(request.id, user_id: user.id, create_twitter_user: true)
    elsif !user.notification_setting.enough_permission_level?
      CreatePeriodicReportMessageWorker.perform_async(user.id, permission_level_not_enough: true)
    else
      CreatePeriodicReportMessageWorker.perform_async(user.id, unauthorized: true)
    end

  rescue => e
    logger.warn "##{__method__} #{e.inspect} dm=#{dm.inspect}"
  end
end
