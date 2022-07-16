class TwitterV1SearchClient
  def initialize(uid: nil, screen_name: nil)
    if uid
      user = User.find_by(uid: uid)
    else
      user = User.find_by(screen_name: screen_name)
    end

    @client = user.api_client.twitter # TwitterClient
  end

  CONVERT_TIME_FORMAT = Proc.new do |time|
    min = time.min - (time.min % 15) # 0, 15, 30, 45
    time.strftime('%Y-%m-%d_%H:') + min.to_s.rjust(2, '0') + ':00_UTC'
  end

  def search(query, options = {})
    options[:count] = 100 unless options[:count]
    query += " since:#{CONVERT_TIME_FORMAT.call(options.delete(:since))}" if options[:since]
    query += " until:#{CONVERT_TIME_FORMAT.call(options.delete(:until))}" if options[:until]
    @client.search(query, options)
  end
end

