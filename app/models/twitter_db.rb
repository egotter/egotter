module TwitterDB
  def self.table_name_prefix
    'twitter_db_'
  end
end

if File.basename($0) == 'annotate' && Rails.env.development?
  TwitterDb = TwitterDB
end