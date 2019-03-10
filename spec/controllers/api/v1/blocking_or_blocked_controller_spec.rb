require 'rails_helper'

RSpec.describe Api::V1::BlockingOrBlockedController, type: :controller do
  describe '#summary_uids' do
    let(:method_name) { :blocking_or_blocked_uids}
    let(:return_value) { [1, 2, 3] }
    it_should_behave_like 'Fetch uids by #summary_uids'
  end

  describe '#list_users' do
    let(:method_name) { :blocking_or_blocked }
    let(:return_value) { [1, 2, 3] }
    it_should_behave_like 'Fetch users by #list_users'
  end
end
