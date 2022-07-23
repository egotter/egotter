# == Schema Information
#
# Table name: slack_messages
#
#  id         :bigint(8)        not null, primary key
#  channel    :string(191)
#  message    :text(65535)
#  properties :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_slack_messages_on_created_at  (created_at)
#
class SlackMessage < ApplicationRecord
  before_validation do
    self.channel.remove!(/^#/) if channel
  end

  def permanent_link
    response = properties['response']
    "https://egotter.slack.com/archives/#{response['channel']}/p#{response['ts'].remove('.')}"
  rescue => e
    Airbag.exception e, id: id
    nil
  end
end
