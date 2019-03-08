require 'rails_helper'

RSpec.describe Unfollowership, type: :model do
  it_should_behave_like 'Importable followership'

  let(:method_name) { :calc_unfollower_uids }
  it_should_behave_like 'Importable by import_by!'
end
