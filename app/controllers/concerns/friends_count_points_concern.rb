require 'active_support/concern'

module FriendsCountPointsConcern
  extend ActiveSupport::Concern

  included do
    before_action { valid_uid?(params[:uid]) }
    before_action { head :forbidden unless SearchRequest.request_for(current_user&.id, uid: params[:uid]) }

    rescue_from Rack::Timeout::RequestTimeoutException do |e|
      Airbag.warn "#{e.message} user_id=#{current_user&.id} controller=#{controller_path} action=#{action_name}"
      head :request_timeout unless performed?
    end
  end

  def validated_limit(max = 30)
    params[:limit]&.match?(/\A[1-9][0-9]\z/) && params[:limit].to_i < max ? params[:limit].to_i : max
  end

  def convert_to_chart_format(records, type)
    if type == 'timestamp'
      records.map { |r| [r.date.to_time.to_i * 1000, r.val.to_i] }
    else
      records.map { |r| [r.date, r.val.to_i] }
    end
  end

  def message_options(records)
    {
        since_date: convert_to_ja_date(records[0].date),
        until_date: convert_to_ja_date(records[-1].date),
        diff_count: (records[0].val.to_i - records[-1].val.to_i).abs,
        current_count: records[-1].val.to_i,
        increased: records[0].val.to_i <= records[-1].val.to_i,
    }
  end

  def convert_to_ja_date(date)
    date.strftime('%m月%d日')
  end
end
