namespace :tmp_search_logs do
  desc 'create'
  task create: :environment do
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS tmp_search_logs')
    ActiveRecord::Base.connection.execute('CREATE TABLE tmp_search_logs LIKE search_logs')
    ActiveRecord::Base.connection.execute('ALTER TABLE tmp_search_logs CHANGE id id INT(11) NOT NULL')
    ActiveRecord::Base.connection.execute("ALTER TABLE tmp_search_logs ADD unified_referer varchar(191) not null default '' after referer")
    ActiveRecord::Base.connection.execute("ALTER TABLE tmp_search_logs ADD unified_channel varchar(191) not null default '' after channel")
  end

  desc 'import'
  task import: :environment do
    first_day = Time.zone.parse(ENV['FIRST']) || Time.zone.today
    last_day = Time.zone.parse(ENV['LAST']) || Time.zone.today
    1000.times do |n|
      day = first_day + n.days
      break if day > last_day

      puts "import: #{day.to_s(:db)}"

      sql = ActiveRecord::Base.send(:sanitize_sql_array, [import_tmp_search_logs_sql, start: day.beginning_of_day, end: day.end_of_day])
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end

def import_tmp_search_logs_sql
  <<-"SQL".strip_heredoc
      INSERT INTO tmp_search_logs
      SELECT
        a.id,
        a.session_id,
        a.user_id,
        a.uid,
        a.screen_name,
        a.action,
        a.ego_surfing,
        a.method,
        a.device_type,
        a.os,
        a.browser,
        a.user_agent,
        a.referer,
        case
          when b.referer like '%egotter%' then 'EGOTTER'
          when b.referer like '%google%' then 'GOOGLE'
          when b.referer like '%yahoo%' then 'YAHOO'
          when b.referer like '%naver%' then 'NAVER'
          when b.referer regexp '(mobile\.)?twitter\.com|t\.co' then 'TWITTER'
          else b.referer
        end unified_referer,
        a.channel,
        case
        when b.channel like '%egotter%' then 'EGOTTER'
        when b.channel like '%google%' then 'GOOGLE'
        when b.channel like '%yahoo%' then 'YAHOO'
        when b.channel like '%naver%' then 'NAVER'
        when b.channel regexp '(mobile\.)?twitter\.com|t\.co' then 'TWITTER'
        else b.channel
        end unified_channel,
        a.medium,
        a.created_at
      FROM search_logs a JOIN (
        SELECT
          id,
          if(referer = '', 'NULL',
             SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(referer, '/', 3), '://', -1), '/', 1), '?', 1)
          ) referer,
          if(channel = '', 'NULL', channel) channel
        FROM search_logs
        WHERE
          created_at BETWEEN :start AND :end
      ) b ON (a.id = b.id)
  SQL
end