require 'rails_helper'

RSpec.describe InactiveMutualFriendship, type: :model do
  let(:klass) { InactiveMutualFriendship }
  it_should_behave_like 'Importable friendship'
end
