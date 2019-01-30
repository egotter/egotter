require 'rails_helper'

RSpec.describe OneSidedFollowership, type: :model do
  let(:klass) { OneSidedFollowership }
  it_should_behave_like 'Importable followership'
end
