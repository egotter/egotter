require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/analytics_v3'

class GoogleAnalyticsClient

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  SCOPE = Google::Apis::AnalyticsV3::AUTH_ANALYTICS
  PROFILE_ID = ENV['GOOGLE_ANALYTICS_PROFILE_ID']

  def initialize
    @client = Google::Apis::AnalyticsV3::AnalyticsService.new
    @client.authorization = build_credentials
  end

  def active_users
    @client.get_realtime_data("ga:#{PROFILE_ID}", 'rt:activeUsers').totals_for_all_results['rt:activeUsers']
  end

  # puts result.column_headers.map { |h| h.name }.inspect
  # => ["rt:deviceCategory", "rt:medium", "rt:source", "rt:userType", "rt:pagePath", "rt:activeUsers"]
  #
  # result.rows.each { |row| puts row.inspect }
  # => ["DESKTOP", "(none)", "(direct)", "NEW", "/searches/aaa?locale=ja", "100"]
  #
  # rt:deviceCategory -> DESKTOP, MOBILE, TABLET
  # rt:medium         -> (none), ORGANIC, REFERRAL, SOCIAL
  # rt:source         -> (direct), google, yahoo, Naver, Twitter, domain.com
  # rt:userType       -> NEW, RETURNING
  # rt:pagePath       -> /aaa/bbb?c=ddd
  #
  # https://developers.google.com/analytics/devguides/reporting/realtime/dimsmets/user?hl=ja
  #
  def realtime_data(metrics: %w(rt:activeUsers), dimensions: %w(rt:deviceCategory rt:medium rt:source rt:userType rt:pagePath))
    @client.get_realtime_data(
        "ga:#{PROFILE_ID}",
        metrics.join(','),
        dimensions: dimensions.join(','),
        sort: dimensions.join(',')
    )
  end

  private

  def build_credentials
    client_id = Google::Auth::ClientId.from_file('.google/client_secret.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: '.google/credentials.yaml')
    Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store).get_credentials('default')
  end
end
