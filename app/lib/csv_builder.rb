require 'csv'

class CsvBuilder
  def initialize(users, with_description: false)
    @users = users
    @with_description = with_description
    @headers = %w(uid name screen_name statuses_count friends_count followers_count description)
  end

  def build
    CSV.generate(headers: @headers, write_headers: true, force_quotes: true) do |csv|
      @users.map do |user|
        csv << @headers.map { |attr| user[attr] }
      end

      if @users.size == 100 && !@with_description
        csv << ['-1', I18n.t('download.data.users_size_note')]
      end
    end
  end
end
