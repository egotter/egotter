shared_examples_for 'Accept any kind of keys' do
  let(:output) { {id: 1}.to_json }
  subject { described_class.send(method_name, input) }

  context 'With symbol key' do
    let(:input) { {id: 1} }
    it { is_expected.to eq(output) }
  end

  context 'With string key' do
    let(:input) { {'id' => 1} }
    it { is_expected.to eq(output) }
  end

  context 'With Hashie::Mash with symbol key' do
    let(:input) { Hashie::Mash.new(id: 1) }
    it { is_expected.to eq(output) }
  end

  context 'With Hashie::Mash with string key' do
    let(:input) { Hashie::Mash.new('id' => 1) }
    it { is_expected.to eq(output) }
  end
end
