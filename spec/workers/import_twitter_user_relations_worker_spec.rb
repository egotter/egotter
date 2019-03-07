require 'rails_helper'

RSpec.describe ImportTwitterUserRelationsWorker do
  let(:twitter_user) { create(:twitter_user) }
  let(:instance) { described_class.new }
  let(:client) { ApiClient.instance }
end
