require 'rails_helper'

RSpec.describe Api::V1::BlockingOrBlockedController, type: :controller do
  let(:method_name) { :blocking_or_blocked_uids}
  let(:return_value) { [1, 2, 3] }
  it_should_behave_like 'Define #summary_uids and #list_uids'
end
