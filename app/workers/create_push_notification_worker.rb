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
    access_key = FirebaseMessagingAuthorization.new.fetch do
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open('.firebase/client_secret.json'),
          scope: 'https://www.googleapis.com/auth/firebase.messaging'
      )
      access_token = authorizer.fetch_access_token!
      "#{access_token['token_type']} #{access_token['access_token']}"
    end

    body = {
        message: {
            token: User.find(user_id).credential_token.instance_id,
            notification: {
                title: title,
                body: body
            },
            android: {
                notification: {
                    channel_id: 'fcm_default_channel'
                }
            }
        }
    }

    uri = URI.parse("https://fcm.googleapis.com/v1/projects/#{ENV['FIREBASE_PROJECT_ID']}/messages:send")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = access_key
    req.body = body.to_json

    res = https.request(req)
    res.body

  rescue => e
    logger.warn "#{e.inspect} #{user_id} #{title} #{body} #{options.inspect} #{"Caused by #{e.cause.inspect}" if e.cause}"
    notify_airbrake(e, user_id: user_id, title: title, body: body, options: options)
  end
end
