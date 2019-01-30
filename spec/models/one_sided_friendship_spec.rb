require 'rails_helper'

RSpec.describe OneSidedFriendship, type: :model do
  let(:klass) { OneSidedFriendship }
  it_should_behave_like 'Importable friendship'
end
