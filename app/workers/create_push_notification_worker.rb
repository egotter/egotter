require 'googleauth'

class CreatePushNotificationWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: 'messaging', retry: 0, backtrace: false

  def unique_key(user_id, title, body, options = {})
    user_id
  end

  def unique_in
    1.minute
  end

  def after_skip(*args)
    logger.warn "Skipped #{args.inspect}"
  end

  def timeout_in
    1.minute
  end

  # options:
  def perform(user_id, title, body, options = {})
    user = User.find(user_id)
    if user.credential_token.instance_id.blank?
      raise "instance_id is blank #{user_id}"
    end

    payload = data_payload(user, title, body)
    res = send_push_notification(payload)

    if res.has_key?('error')
      if requested_entity_not_found?(res)
        logger.warn "NOT FOUND #{res}"
      else
        logger.warn res
      end
    else
      logger.info res
    end

  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{title} #{body} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    notify_airbrake(e, user_id: user_id, title: title, body: body, options: options)
  end

  private

  def requested_entity_not_found?(res)
    (error = res['error']) &&
        error['code'] == 404 &&
        error['message'] == 'Requested entity was not found.'
  end

  def send_push_notification(payload)
    uri = URI.parse("https://fcm.googleapis.com/v1/projects/#{ENV['FIREBASE_PROJECT_ID']}/messages:send")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.open_timeout = 3
    https.read_timeout = 3
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = access_key
    req.body = payload.to_json
    JSON.parse(https.request(req).body)
  end

  def access_key
    FirebaseMessagingAuthorization.new.fetch do
      json_key = '.firebase/client_secret.json'
      unless File.exist?(json_key)
        raise "json key file not found #{json_key}"
      end

      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(json_key),
          scope: 'https://www.googleapis.com/auth/firebase.messaging'
      )
      access_token = authorizer.fetch_access_token!
      "#{access_token['token_type']} #{access_token['access_token']}"
    end
  end

  def notification_payload(user_id, title, body)
    {
        message: {
            token: User.find(user_id).credential_token.instance_id,
            notification: {
                title: title,
                body: body
            },
            android: {
                collapse_key: '1',
                notification: {
                    channel_id: 'fcm_default_channel'
                }
            }
        }
    }
  end

  def data_payload(user, title, body)
    data = {
        title: title,
        body: body,
        uid: user.uid,
        screen_name: user.screen_name,
        version_code: ENV['ANDROID_VERSION_CODE']
    }

    if (twitter_user = TwitterUser.latest_by(uid: user.uid))
      data.merge!(twitter_user.summary_counts)
    end

    data.each { |k, v| data[k] = v.to_s }

    {
        message: {
            token: user.credential_token.instance_id,
            data: data
        }
    }
  end
end
