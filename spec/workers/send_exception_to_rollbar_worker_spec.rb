require 'rails_helper'

RSpec.describe SendExceptionToRollbarWorker do
  describe '#traverse_hash' do
    let(:worker) { described_class.new }
    subject { worker.traverse_hash('exception', hash) }

    context 'One level nested' do
      let(:hash) { {'exception' => 'found'} }
      it { expect { subject }.to raise_error('found') }
    end

    context 'Two level nested' do
      let(:hash) { {'key' => {'exception' => 'found'}} }
      it { expect { subject }.to raise_error('found') }
    end

    context 'Nested in array' do
      let(:hash) { {'key' => [{'name' => 'nick'}, {'exception' => 'found'}]} }
      it { expect { subject }.to raise_error('found') }
    end

    context 'Not included' do
      let(:hash) { {'key' => [{'name' => 'nick'}, {'phone' => '000'}]} }
      it { expect { subject }.not_to raise_error }
    end
  end
end
