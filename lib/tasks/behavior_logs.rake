namespace :behavior_logs do
  desc 'build sessions'
  task build_sessions: :environment do
    start_day = Time.zone.parse(ENV['START'])
    end_day = Time.zone.parse(ENV['END'])
    sessions = Hash.new({days: [], user_ids: Set.new})

    (start_day.to_date..end_day.to_date).each do |day|
      search_logs = SearchLog.except_crawler.where(created_at: day.to_time.all_day)
      search_logs, rejected = search_logs.partition { |log| ['', '-1'].exclude?(log.session_id) }

      search_logs.each.with_index do |log, i|
        session = sessions[log.session_id]
        session[:days] << day
        session[:user_ids].add log.user_id
        if i < 10
          puts "#{sessions.keys.size}"
          puts "#{sessions.inspect}"
          puts "#{session.inspect}"
        else
          break
        end
      end

      puts "#{day}: #{search_logs.size}, #{rejected.size}"
    end

    File.write('sessions.json', JSON.dump(sessions))
  end

  desc 'verify sessions'
  task verify_sessions: :environment do
    # A session_id has many user_ids -> NG
    # A user_id has many session_ids -> OK

    sessions = JSON.load(File.read('sessions.json', encoding: Encoding::UTF_8))
    sessions.each do |session_id, session|
      if session[:user_ids].many? { |user_id| user_id != -1 }
        puts "#{session_id} has many user_ids: [#{session[:user_ids].join(', ')}]"
      end
    end
  end

  desc 'save sessions'
  task save_sessions: :environment do
    behavior_logs = []

    sessions = JSON.load(File.read('sessions.json', encoding: Encoding::UTF_8))
    sessions.each do |session_id, session|
      behavior = {}

      session[:days].each do |day|
        activities = {}

        search_logs = SearchLog.where(created_at: day.all_day).where(session_id: session_id)
        if search_logs.any?
          activities[:search_log_ids] = search_logs.pluck(:id)
          activities[:user_ids] = search_logs.pluck(:user_id).uniq
        end

        background_search_logs = BackgroundSearchLog.where(created_at: day.all_day, session_id: session_id)
        if background_search_logs.any?
          activities[:background_search_log_ids] = background_search_logs.pluck(:id)
        end

        if activities.any?
          behavior[I18n.l(day, format: :date_hyphen)] = activities
        end
      end

      log = BehaviorLog.find_or_initialize_by(session_id: session_id)
      log.assign_attributes(json: JSON.dump(behavior))

      user = User.find_by(id: session[:user_ids].find { |user_id| user_id != -1 })
      if user
        log.assign_attributes(user_id, user.id, uid: user.uid, screen_name: user.screen_name)
      else
        log.assign_attributes(user_id, -1, uid: -1, screen_name: '-1')
      end

      behavior_logs << log
      if behavior_logs.size > 1000
        BehaviorLog.import(behavior_logs, validate: false)
        behavior_logs = []
      end
    end
  end
end
