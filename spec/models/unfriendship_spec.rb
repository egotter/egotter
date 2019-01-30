require 'rails_helper'

RSpec.describe Unfriendship, type: :model do
  let(:klass) { Unfriendship }
  it_should_behave_like 'Importable friendship'
end
