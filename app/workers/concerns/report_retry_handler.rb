require 'active_support/concern'

module ReportRetryHandler
  extend ActiveSupport::Concern

  def report_retry_delay
    1.hour + rand(30).minutes
  end

  def retry_current_report(*job_args, exception: nil)
    logger.add(exception ? Logger::WARN : Logger::INFO) { "#{self.class} will be performed again exception=#{exception.inspect} job_args=#{job_args.inspect.truncate(150)}" }
    self.class.perform_in(report_retry_delay, *job_args)
  end
end
