module Task
  class PromptReportsTask < Task::Base
    def self.invoke(user_ids, deadline: nil)
      self.new.process_jobs(CreatePromptReportWorker, user_ids, deadline)
    end
end
