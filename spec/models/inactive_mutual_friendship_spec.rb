require 'rails_helper'

RSpec.describe InactiveMutualFriendship, type: :model do
  let(:klass) { described_class }
  it_should_behave_like 'Importable friendship'

  let(:method_name) { :calc_inactive_mutual_friend_uids }
  it_should_behave_like 'Importable by import_by!'
end
