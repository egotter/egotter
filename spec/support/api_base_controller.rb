shared_examples_for 'Fetch uids by #summary_uids' do
  let(:twitter_user) { create(:twitter_user) }
  let(:controller) { described_class.new }
  before { controller.instance_variable_set(:@twitter_user, twitter_user) }

  subject { controller.send(:summary_uids) }

  it do
    expect(twitter_user).to receive(method_name).and_call_original
    subject
  end

  context 'With result' do
    before { allow(twitter_user).to receive(method_name).and_return(return_value) }
    it {is_expected.to eq([return_value, return_value.size])}
  end

  context 'Without result' do
    it {is_expected.to eq([[], 0])}
  end
end

shared_examples_for 'Fetch users by #list_users' do
  let(:twitter_user) { create(:twitter_user) }
  let(:controller) { described_class.new }
  before { controller.instance_variable_set(:@twitter_user, twitter_user) }

  # let(:min_sequence) { 0 }
  # let(:limit) { 3 }
  subject { controller.send(:list_users) }

  it do
    expect(twitter_user).to receive(method_name).and_call_original
    subject
  end

    # context 'With result' do
    #   before { allow(twitter_user).to receive(method_name).and_return(return_value) }
    #   it {is_expected.to eq([return_value.to_a, min_sequence + return_value.size - 1])}
    # end
    #
    # context 'Without result' do
    #   it {is_expected.to eq([[], -1])}
    # end
end
