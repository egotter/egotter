require 'rails_helper'

RSpec.describe InactiveFollowership, type: :model do
  let(:klass) { described_class }
  it_should_behave_like 'Importable followership'

  let(:method_name) { :calc_inactive_follower_uids }
  it_should_behave_like 'Importable by import_by!'
end
