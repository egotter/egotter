class Task < ActiveRecord::Base
  include ActiveModel::Model

  attr_accessor :name, :user_ids

  def file_path
    Rails.root.join 'tmp', "#{name.gsub(':', '_')}.log"
  end

  def invoke
    case name
      when 'twitter_users:send_prompt_reports'
        ::Task::PromptReportsTask.invoke(user_ids)
      else raise "[#{name}] is not allowed."
    end
  end
end
