shared_examples_for 'Define #summary_uids and #list_uids' do
  let(:twitter_user) { create(:twitter_user) }
  let(:controller) { described_class.new }
  before { controller.instance_variable_set(:@twitter_user, twitter_user) }

  describe '#summary_uids' do
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

  describe '#list_uids' do
    let(:min_sequence) { 0 }
    let(:limit) { 3 }
    subject { controller.send(:list_uids, min_sequence, limit: limit) }

    it do
      expect(twitter_user).to receive(method_name).and_call_original
      subject
    end

    context 'With result' do
      before { allow(twitter_user).to receive(method_name).and_return(return_value) }
      it {is_expected.to eq([return_value.to_a, min_sequence + return_value.size - 1])}
    end

    context 'Without result' do
      it {is_expected.to eq([[], -1])}
    end
  end
end
