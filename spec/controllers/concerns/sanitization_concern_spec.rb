require 'rails_helper'

RSpec.describe SanitizationConcern do
  controller ApplicationController do
    include SanitizationConcern
  end

  describe '#sanitized_redirect_path' do
    subject { controller.sanitized_redirect_path(path) }

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
        it { is_expected.to match(/sanitization_failed/) }
      end
    end
  end
end
