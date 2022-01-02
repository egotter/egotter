require 'csv'

class CsvBuilder
  def initialize(users, with_description: false)
    @users = users
    @with_description = with_description
    @headers = %w(uid name screen_name statuses_count friends_count followers_count description)
  end

  def build
    CSV.generate(headers: @headers, write_headers: true, force_quotes: true) do |csv|
      @users.each do |user|
        csv << @headers.map { |attr| user[attr] }
      end

      if !@with_description && @users.size == Order::FREE_PLAN_USERS_LIMIT
        url = Rails.application.routes.url_helpers.pricing_url(via: 'download_100')
        csv << ['-1', I18n.t('download.data.note1', count: 100, url: url)]
      end

      if @with_description && @users.size == Order::BASIC_PLAN_USERS_LIMIT
        url = Rails.application.routes.url_helpers.pricing_url(via: 'download_10000')
        csv << ['-1', I18n.t('download.data.note2', count: 10000, url: url)]
      end
    end
  end
end
