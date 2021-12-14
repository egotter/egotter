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

  def generate_chart_data(klass, uid)
    records = klass.group_by_day(uid, 29.days.ago, Time.zone.now, params[:padding])
    data = convert_to_chart_format(records, params[:type])

    if params[:with_prev]
      prev_records = klass.group_by_day(uid, 59.days.ago, 30.days.ago, params[:padding])
      prev_data = data.map.with_index { |(date, _), i| [date, prev_records[i].val&.to_i] }
      series = [
          {name: t('.period'), data: data, dashStyle: 'solid', color: '#7cb5ec'},
          {name: t('.prev_period'), data: prev_data, dashStyle: 'dot', color: '#7cb5ec'},
      ]
    else
      series = [
          {name: t('.name'), data: data, dashStyle: 'solid', color: '#7cb5ec'},
      ]
    end

    {series: series, message: chart_message(uid, records)}
  end

  def generate_csv(klass, uid)
    records = klass.group_by_day(uid, 29.days.ago, Time.zone.now, params[:padding])
    data = convert_to_chart_format(records, nil)

    if params[:with_prev]
      prev_records = klass.group_by_day(uid, 59.days.ago, 30.days.ago, params[:padding])
      data.each.with_index { |d, i| d << prev_records[i].val&.to_i }
      headers = %w(Date Current Previous)
    else
      headers = %w(Date Current)
    end

    CSV.generate(headers: headers, write_headers: true) do |csv|
      data.each { |d| csv << d }
    end
  end

  def convert_to_chart_format(records, type)
    if type == 'timestamp'
      records.map { |r| [r.date.to_time.to_i * 1000, r.val&.to_i] }
    else
      records.map { |r| [r.date, r.val&.to_i] }
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
