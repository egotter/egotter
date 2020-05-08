require 'openssl'
require 'base64'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :twitter

  def challenge
    render json: {response_token: crc_response}
  end

  def twitter
    if verified_webhook_request? && params[:for_user_id].to_i == User.egotter.uid && params[:direct_message_events]
      params[:direct_message_events].each do |event|
        if event['type'] == 'message_create'
          dm = DirectMessage.new(event: event.to_unsafe_h.deep_symbolize_keys)

          if sent_from_user?(dm)
            GlobalDirectMessageReceivedFlag.new.received(dm.sender_id)
            enqueue_user_requested_periodic_report(dm)
            SendReceivedMessageWorker.perform_async(dm.sender_id, dm_id: dm.id, text: dm.text)
          elsif sent_from_egotter?(dm)
            enqueue_egotter_requested_periodic_report(dm)
            SendSentMessageWorker.perform_async(dm.recipient_id, dm_id: dm.id, text: dm.text)
          end
        end
      end
    end

    head :ok
  rescue => e
    logger.warn "#{controller_name}##{action_name} #{e.inspect}"
    notify_airbrake(e)
    head :ok
  end

  private

  def sent_from_user?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id != User.egotter.uid
  end

  def sent_from_egotter?(dm)
    dm.text.exclude?('#egotter') && dm.sender_id == User.egotter.uid
  end

  # t('quick_replies.prompt_reports.label3')
  SEND_NOW_REGEXP = /(今すぐ|いますぐ)(送信|そうしん|受信|じゅしん|痩身|通知)/

  def send_now_requested?(dm)
    dm.text.match?(SEND_NOW_REGEXP)
  end

  CONTINUE_WORDS = %w(継続 けいぞく 再開 復活 届いてません フォローしました フォローしたよ テスト送信 届きました 初期設定 届きました 通知がきません 早くしろよ まだですか ぴえん)
  CONTINUE_REGEXP = Regexp.union(CONTINUE_WORDS)

  def continue_requested?(dm)
    dm.text.match?(CONTINUE_REGEXP)
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

  def crc_response
    crc_digest(params[:crc_token])
  end

  # NOTICE The name #verified_request? conflicts with an existing method in Rails.
  def verified_webhook_request?
    crc_digest(request.body.read) == request.headers[:HTTP_X_TWITTER_WEBHOOKS_SIGNATURE]
  end

  def crc_digest(payload)
    secret = ENV['TWITTER_CONSUMER_SECRET']
    digest = OpenSSL::HMAC::digest('sha256', secret, payload)
    "sha256=#{Base64.encode64(digest).strip!}"
  end
end
