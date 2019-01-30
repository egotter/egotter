require 'rails_helper'

RSpec.describe FavoriteFriendship, type: :model do
  let(:klass) { FavoriteFriendship }
  it_should_behave_like 'Importable friendship'
end
