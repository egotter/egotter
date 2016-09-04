class Onesignal
  def self.send(user_ids)
    params = params(user_ids)
    puts JSON.pretty_generate(params)
    post(params)
  end

  private

  def self.params(user_ids)
    user_ids = user_ids.map(&:to_i).map { |user_id| {field: :tag, key: :user_id, relation: '=', value: user_id} }
    filters = user_ids.many? ? user_ids.each_cons(2).map { |arr| [arr[0], {operator: :OR}, arr[1]] }.flatten : user_ids
    {
      app_id: ENV['ONESIGNAL_APP_ID'],
      rest_api_key: ENV['ONESIGNAL_API_KEY'],
      headings: {en: I18n.t('onesignal.defaultNotification.title', locale: :en), ja: I18n.t('onesignal.defaultNotification.title', locale: :ja)},
      contents: {en: I18n.t('onesignal.defaultNotification.message', locale: :en), ja: I18n.t('onesignal.defaultNotification.message', locale: :ja)},
      filters: filters,
      web_buttons: [
        {'id': 'settings-button', 'text': 'Settings', 'icon': 'https://egotter.com/onesignal/font-awesome_4-6-3_cog_256_0_7f8c8d_none.png', 'url': Rails.application.routes.url_helpers.menu_url},
      ],
    }
  end

  def self.post(params)
    uri = URI.parse('https://onesignal.com/api/v1/notifications')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json', 'Authorization' => "Basic #{params[:rest_api_key]}")
    request.body = params.to_json
    http.request(request)
  end
end