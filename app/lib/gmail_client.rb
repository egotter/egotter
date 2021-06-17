require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/gmail_v1'

class GmailClient

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

  # https://developers.google.com/identity/protocols/oauth2/scopes
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_MODIFY

  def initialize(user_id)
    @client = Google::Apis::GmailV1::GmailService.new
    @client.authorization = service_account_authorization(user_id)
  end

  def user(user_id: 'me')
    @client.get_user_profile(user_id)
  end

  def messages(user_id: 'me')
    @client.list_user_messages(user_id).messages
  end

  def message(message_id, user_id: 'me')
    @client.get_user_message(user_id, message_id)
  end

  def send_message(from, to, subject, body)
    message = Mail.new
    message.from = from
    message.to = to
    message.subject = subject
    message.body = body
    encoded_message = Google::Apis::GmailV1::Message.new(raw: message.to_s)
    @client.send_user_message('me', encoded_message)
  end

  def service_account_authorization(user_id)
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open('.google/service_account_gmail.json'),
        scope: SCOPE
    )

    credentials.sub = user_id
    credentials.fetch_access_token!
    credentials
  end

  def oauth_authorization
    client_id = Google::Auth::ClientId.from_file('.google/client_secret_gmail.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: '.google/credentials_gmail.yaml')
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)

    if (credentials = authorizer.get_credentials('default')).nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open #{url} in your browser and enter the resulting code:"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: 'default', code: code, base_url: OOB_URI)
    end

    credentials
  end
end
