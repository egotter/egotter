require 'rails_helper'

RSpec.describe DeleteTweetsRequestDecorator do
  let(:user) { create(:user) }
  let(:request) { DeleteTweetsRequest.create(user: user) }
  let(:decorator) { described_class.new(request) }

  describe '#message' do
    subject { decorator.message }
    it { is_expected.to be_truthy }
  end

  describe '#display_time' do
    subject { decorator.display_time }
    it { is_expected.to be_truthy }
  end
end
