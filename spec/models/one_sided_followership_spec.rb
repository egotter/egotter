require 'rails_helper'

RSpec.describe OneSidedFollowership, type: :model do
  let(:klass) { described_class }
  it_should_behave_like 'Importable followership'

  let(:method_name) { :calc_one_sided_follower_uids }
  it_should_behave_like 'Importable by import_by!'
end
