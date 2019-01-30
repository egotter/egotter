require 'rails_helper'

RSpec.describe Unfollowership, type: :model do
  let(:klass) { Unfollowership }
  it_should_behave_like 'Importable followership'
end
