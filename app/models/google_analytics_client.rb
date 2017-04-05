require 'google/apis/analytics_v3'
require 'googleauth/stores/file_token_store'

class GoogleAnalyticsClient

  PROFILE_ID = ENV['GOOGLE_ANALYTICS_PROFILE_ID']

  def initialize
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = user_credentials_for(Google::Apis::AnalyticsV3::AUTH_ANALYTICS)
  end

  def active_users
    @analytics.get_realtime_data("ga:#{PROFILE_ID}", 'rt:activeUsers').totals_for_all_results['rt:activeUsers']
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
    @analytics.get_realtime_data(
      "ga:#{PROFILE_ID}",
      metrics.join(','),
      dimensions: dimensions.join(','),
      sort: dimensions.join(',')
    )
  end

  private

  def user_credentials_for(scope)
    token_store_path = File.join(ENV['GOOGLE_TOKEN_STORE_PATH'])
    FileUtils.mkdir_p(File.dirname(token_store_path))
    client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: token_store_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)
    authorizer.get_credentials('default')
  end
end
