require 'rails_helper'

RSpec.describe InactiveFriendship, type: :model do
  let(:klass) { InactiveFriendship }
  it_should_behave_like 'Importable friendship'
end
