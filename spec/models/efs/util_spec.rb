require 'rails_helper'

RSpec.describe Efs::Util do
  let(:klass) { Class.new { extend Efs::Util } }

  describe '.parse_json' do
    subject { klass.parse_json({a: 1}.to_json) }
    it { is_expected.to satisfy { |result| result[:a] == 1 } }
  end

  describe '.compress' do
    subject { klass.compress('a') }
    it { is_expected.to be_truthy }
  end

  describe '.decompress' do
    let(:data) { Zlib::Deflate.deflate('abc') }
    subject { klass.decompress(data) }
    it { is_expected.to eq('abc') }
  end
end
