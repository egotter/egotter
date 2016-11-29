class Task
  include ActiveModel::Model

  attr_accessor :name, :user_ids

  def file_path
    Rails.root.join 'tmp', "#{name.gsub(':', '_')}.log"
  end

  def invoke(cli_or_web = 'cli')
    case name
      when 'twitter_users:send_prompt_reports'
        ::Tasks::PromptReportsTask.invoke(user_ids, cli_or_web)
      else raise "[#{name}] is not allowed."
    end
  end
end
