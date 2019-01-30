require 'rails_helper'

RSpec.describe BlockFriendship, type: :model do
  let(:klass) { BlockFriendship }
  it_should_behave_like 'Importable friendship'
end
