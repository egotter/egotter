class Onesignal
  attr_reader :user_id, :headings, :contents, :url

  # headings = {en: 'Title', ja: 'タイトル'}
  # contents = {en: 'Message', ja: 'メッセージ'}
  def initialize(user_id, headings:, contents:, url:)
    @user_id = user_id
    @headings = headings
    @contents = contents
    @url = url
  end

  def send
    filters = self.class.post_filters([user_id])
    values = self.class.post_values(filters: filters, headings: headings, contents: contents, url: url)
    self.class.post(values)
  end

  private

  def self.post_values(filters:, headings:, contents:, url:)
    {
      app_id: ENV['ONESIGNAL_APP_ID'],
      rest_api_key: ENV['ONESIGNAL_API_KEY'],
      headings: headings,
      contents: contents,
      filters: filters,
      web_buttons: [
        {
          id: 'settings-button',
          text: 'Settings',
          icon: 'https://egotter.com/onesignal/font-awesome_4-6-3_cog_256_0_7f8c8d_none.png',
          url: url
        },
      ],
    }
  end

  def self.post_filters(user_ids)
    user_ids = user_ids.map(&:to_i).map { |user_id| {field: :tag, key: :user_id, relation: '=', value: user_id} }
    user_ids.many? ? user_ids.each_cons(2).map { |arr| [arr[0], {operator: :OR}, arr[1]] }.flatten : user_ids
  end

  def self.post(values)
    uri = URI.parse('https://onesignal.com/api/v1/notifications')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json', 'Authorization' => "Basic #{values[:rest_api_key]}")
    request.body = values.to_json
    http.request(request)
  end
end
