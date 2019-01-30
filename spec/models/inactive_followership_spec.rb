require 'rails_helper'

RSpec.describe InactiveFollowership, type: :model do
  let(:klass) { InactiveFollowership }
  it_should_behave_like 'Importable followership'
end
