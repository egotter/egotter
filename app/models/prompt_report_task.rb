class PromptReportTask

  attr_accessor :processed_count

  class << self
    def start(user_ids_str:, deadline_str: nil)
      new(user_ids_str, deadline_str)
    end

    def logger
      logger = ActiveSupport::Logger.new(Rails.root.join('log/batch.log'))
      logger.level = Rails.logger.level
      logger.formatter = ::Logger::Formatter.new

      console = ActiveSupport::Logger.new(STDOUT)
      console.formatter = ::Logger::Formatter.new
      logger.extend ActiveSupport::Logger.broadcast(console)

      logger
    end
  end

  def initialize(user_ids_str, deadline_str)
    @start_time = Time.zone.now
    @processed_count = 0
    @errors = []

    @user_ids =
        case
        when user_ids_str.blank? then User.pluck(:id)
        when user_ids_str.include?('..') then Range.new(*user_ids_str.split('..').map(&:to_i))
        when user_ids_str.include?(',') then user_ids_str.remove(' ').split(',').map(&:to_i)
        else [user_ids_str.to_i]
        end

    @deadline =
        case
        when deadline_str.blank? then nil
        when deadline_str.match(/\d+\.(minutes?|hours?)/) then Time.zone.now + eval(ENV['DEADLINE'])
        else Time.zone.parse(deadline_str)
        end
  end

  def errors
    @errors
  end

  def add_error(user_id, e)
    @errors << {time: Time.zone.now, user_id: user_id, error_class: e.class, error_message: e.message.truncate(100)}
  end

  def fatal?
    @processed_count > 20 &&
        @errors.select {|e| e[:error_class].is_a?(CreatePromptReportRequest::Error)}.size >= @processed_count / 10
  end

  def start_time
    @start_time
  end

  def overdue?
    @deadline && @deadline < Time.zone.now
  end

  def users
    @users ||= User.where(id: can_send_ids).select(:id, :uid)
  end

  def user_ids
    @user_ids
  end

  def authorized_ids
    @authorized_ids ||= User.authorized.where(id: user_ids).pluck(:id)
  end

  def active_ids
    @active_ids ||= User.active(14).where(id: authorized_ids).pluck(:id)
  end

  def can_send_ids
    @can_send_ids ||= User.can_send_dm.where(id: active_ids).pluck(:id)
  end

  def ids_stats
    {
        user_ids: user_ids.size,
        authorized_ids: authorized_ids.size,
        active_ids: active_ids.size,
        can_send_ids: can_send_ids.size
    }
  end

  def sent_count
    @sent_count ||= PromptReport.where(created_at: start_time..Time.zone.now).size
  end

  def deadline
    @deadline
  end

  def to_s(kind)
    case kind
    when :deadline
      "deadline #{deadline}"
    when :ids_stats
      "#{ids_stats.map {|k, v| "#{k} #{v}"}.join(', ')}"
    when :progress
      elapsed = Time.zone.now - start_time
      avg = elapsed / (processed_count + 1)
      remaining = deadline ? deadline - Time.zone.now : nil
      "avg #{sprintf('%4.1f', avg)} seconds, elapsed #{sprintf('%d', elapsed)} seconds#{", remaining #{sprintf('%d', remaining)} seconds" if remaining}"
    when :errors
      errors.map do |e|
        "#{e[:time]} #{e[:user_id]} #{e[:error_class]} #{e[:error_message]}"
      end.join("\n")
    when :finishing
      elapsed = Time.zone.now - start_time
      "elapsed #{sprintf('%d', elapsed)} seconds#{", deadline #{deadline}" if deadline}, processed #{processed_count}, sent #{sent_count}, users #{users.size}, errors #{errors.size}"
    else
      raise "Invalid kind #{kind}"
    end
  end
end
