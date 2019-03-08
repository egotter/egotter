require 'rails_helper'

RSpec.describe Api::V1::UnfriendsController, type: :controller do
  let(:method_name) { :unfriendships}
  let(:return_value) { ApplicationRecord.none }
  it_should_behave_like 'Define #summary_uids and #list_uids'
end
