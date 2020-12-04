require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/gmail_v1'

class GmailClient

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

  # https://developers.google.com/identity/protocols/oauth2/scopes
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def initialize
    @client = Google::Apis::GmailV1::GmailService.new
    @client.authorization = build_credentials
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

  def build_credentials
    client_id = Google::Auth::ClientId.from_file('.google/client_secret_gmail.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: '.google/credentials_gmail2.yaml')
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
