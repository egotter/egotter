require 'rails_helper'

RSpec.describe Concerns::SanitizationConcern do
  let(:instance) { double('Instance') }

  before do
    instance.extend Concerns::SanitizationConcern
  end

  describe '#sanitized_redirect_path' do
    subject { instance.sanitized_redirect_path(path) }

    described_class::SAFE_REDIRECT_PATHS.each do |path_str|
      context "path is #{path_str}" do
        let(:path) { path_str }
        it { is_expected.to eq(path_str) }
      end
    end

    [
        'https://example.com',
        'https://egotter.com',
    ].each do |path_str|
      context "path is #{path_str}" do
        let(:path) { path_str }
        it do
          expect(instance).to receive(:root_path)
          subject
        end
      end
    end
  end
end
