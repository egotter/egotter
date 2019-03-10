require 'rails_helper'

RSpec.describe Api::V1::UnfollowersController, type: :controller do
  let(:method_name) { :unfollowerships}
  let(:return_value) { ApplicationRecord.none }
  it_should_behave_like 'Fetch uids by #summary_uids'
end
