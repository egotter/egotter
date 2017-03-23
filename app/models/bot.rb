# == Schema Information
#
# Table name: bots
#
#  id          :integer          not null, primary key
#  uid         :integer          not null
#  screen_name :string(191)      not null
#  secret      :string(191)      not null
#  token       :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bots_on_screen_name  (screen_name)
#  index_bots_on_uid          (uid) UNIQUE
#

class Bot < ActiveRecord::Base
  def self.load(path)
    JSON.parse(File.read(path)).each do |bot|
      create!(uid: bot['uid'], screen_name: bot['screen_name'], secret: bot['secret'], token: bot['token'])
    end
  end

  def self.config(screen_name = nil)
    @@ids ||= pluck(:id)
    bot = screen_name ? find_by(screen_name: screen_name) : find(@@ids.sample)
    ApiClient.config(access_token: bot.token, access_token_secret: bot.secret)
  end

  def self.api_client(screen_name = nil)
    ApiClient.instance(config(screen_name))
  end

  def self.verify_credentials
    processed = Queue.new
    Parallel.each_with_index(pluck(:screen_name), in_threads: 10) do |screen_name, i|
      user = (api_client(screen_name).verify_credentials rescue nil)
      processed << {i: i, screen_name: screen_name, status: !!user}
    end

    processed.size.times.map { processed.pop }.sort_by { |p| p[:i] }.map do |p|
      puts "#{p[:screen_name]} #{p[:status]}"
    end
  end
end
