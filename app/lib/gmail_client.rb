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

  def messages(user_id: 'me', from: nil, to: nil, subject: nil, limit: 3)
    collection = []
    next_page = nil
    q = SearchQuery.new(from, to, subject).to_s

    begin
      options = {max_results: limit, page_token: next_page}
      options.merge!(q: q) if q != ''

      result = @client.list_user_messages(user_id, options)
      collection += result.messages
      break if collection.size >= limit
      next_page = result.next_page_token
    end while next_page

    collection.map { |item| message(item.id) }
  end

  def message(message_id, user_id: 'me')
    result = @client.get_user_message(user_id, message_id)
    Mail.from_payload(result.payload, result)
  end

  def send_message(from, to, subject, body, thread_id: nil)
    message = ::Mail.new
    message.from = from
    message.to = to
    message.subject = subject
    message.body = body
    encoded_message = Google::Apis::GmailV1::Message.new(raw: message.to_s, thread_id: thread_id)
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

  class SearchQuery
    def initialize(from, to, subject)
      @from = from
      @to = to
      @subject = subject
    end

    def to_s
      str = ''
      str += "#{str} from:#{@from}" if @from
      str += "#{str} to:#{@to}" if @to
      str += "#{str} subject:#{@subject}" if @subject
      str
    end
  end

  class Mail
    attr_accessor :subject, :body, :from, :to, :data

    def initialize(subject, body, from, to, data)
      @subject = subject
      @body = body
      @from = from
      @to = to
      @data = data
    end

    def thread_id
      @data.thread_id
    end

    class << self
      def from_payload(message_payload, data)
        subject = select_header(message_payload.headers, 'Subject')
        body = select_body(message_payload)
        from = select_header(message_payload.headers, 'From')
        to = select_header(message_payload.headers, 'To')
        new(subject, body, from, to, data)
      end

      def select_header(headers, name)
        headers.find { |h| h.name == name }&.value
      end

      def select_body(payload)
        unless (body = payload.body.data)
          body = payload.parts.map { |part| part.body.data }.join
        end

        body.force_encoding('UTF-8')
      end
    end
  end
end
