require 'rails_helper'

RSpec.describe CloseFriendship, type: :model do
  let(:klass) { CloseFriendship }
  it_should_behave_like 'Importable friendship'
end
