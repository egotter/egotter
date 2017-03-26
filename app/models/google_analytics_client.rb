require 'google/apis/analytics_v3'
require 'googleauth/stores/file_token_store'

class GoogleAnalyticsClient
  def initialize
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = user_credentials_for(Google::Apis::AnalyticsV3::AUTH_ANALYTICS)
  end

  def active_users
    @analytics.get_realtime_data("ga:#{ENV['GOOGLE_ANALYTICS_PROFILE_ID']}", 'rt:activeUsers').totals_for_all_results['rt:activeUsers']
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
