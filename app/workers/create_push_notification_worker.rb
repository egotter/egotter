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

    access_key = FirebaseMessagingAuthorization.new.fetch do
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

    body = data_payload(user, title, body)

    uri = URI.parse("https://fcm.googleapis.com/v1/projects/#{ENV['FIREBASE_PROJECT_ID']}/messages:send")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = access_key
    req.body = body.to_json

    res = JSON.parse(https.request(req).body)

    if res.has_key?('error')
      logger.warn res
    else
      logger.info res
    end

  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{title} #{body} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    notify_airbrake(e, user_id: user_id, title: title, body: body, options: options)
  end

  private

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
