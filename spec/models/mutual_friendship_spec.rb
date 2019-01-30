require 'rails_helper'

RSpec.describe MutualFriendship, type: :model do
  let(:klass) { MutualFriendship }
  it_should_behave_like 'Importable friendship'
end
