require 'rails_helper'

RSpec.describe DeleteLogsTask, type: :model do
  let(:instance) { described_class.new(SearchLog, nil, nil) }

  describe '#start!' do
    subject { instance.start! }
    before { create(:search_log) }
    it { expect { subject }.to change { SearchLog.all.size }.by(-1) }
  end
end
