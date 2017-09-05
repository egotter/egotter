class JobsController < ApplicationController

  before_action(only: %i(show)) { valid_uid? }
  before_action(only: %i(show)) { searched_uid?(params[:uid].to_i) }

  def show
    uid = params[:uid].to_i
    return head :ok if TwitterUser.exists?(uid: uid)

    job = Job.order(created_at: :desc).find_by(uid: uid, user_id: current_user_id, jid: params['jid'])
    return render json: params.slice(:uid, :jid, :interval, :retry_count), status: 202 if !job || job.processing?
    return head :ok if job.finished? && job.twitter_user_created?

    render json: error_message_json(job), status: 500
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{params.inspect} #{request.referer}"
    render json: error_message_json(job), status: 500
  end

  private

  def error_message_json(job)
    klass = job.error_class.demodulize
    url = sign_in_path(via: "#{controller_name}/#{action_name}/#{klass.underscore}")

    message =
      if user_signed_in?
        case klass
          when 'Unauthorized' then t('after_sign_in.unauthorized_html', sign_in: url, sign_out: sign_out_path)
          when 'TooManyRequests' then t('after_sign_in.too_many_requests_with_reset_in', seconds: (Time.zone.parse(job.error_message) - Time.zone.now).round)
          else t('after_sign_in.something_wrong_html')
        end
      else
        case klass
          when 'Unauthorized' then t('before_sign_in.unauthorized_html', url: url)
          when 'TooManyRequests' then t('before_sign_in.too_many_requests_html', url: url)
          else t('before_sign_in.something_wrong_html', url: url)
        end
      end

    {jid: job.jid, error_class: job.error_class, error_message: job.error_message, message: message}
  end
end
