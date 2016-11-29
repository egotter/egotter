module Tasks
  class PromptReportsTask < Tasks::Base
    def self.invoke(user_ids, cli_or_web, deadline: nil)
      self.new(cli_or_web).process_jobs(CreatePromptReportWorker, user_ids, deadline)
    end
  end
end
