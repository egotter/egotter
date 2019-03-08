require 'rails_helper'

RSpec.describe OneSidedFollowership, type: :model do
  it_should_behave_like 'Importable followership'

  let(:method_name) { :calc_one_sided_follower_uids }
  it_should_behave_like 'Importable by import_by!'
end
