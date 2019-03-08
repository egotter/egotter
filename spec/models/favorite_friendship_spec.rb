require 'rails_helper'

RSpec.describe FavoriteFriendship, type: :model do
  it_should_behave_like 'Importable friendship'

  let(:method_name) { :calc_favorite_friend_uids }
  it_should_behave_like 'Importable by import_by!'
end
