require 'rails_helper'

RSpec.describe Concerns::WorkerUtils do
end

RSpec.describe Concerns::WorkerUtils::WorkerError do
  describe '#full_message' do
    let(:worker_class) { TestWorker = Class.new }
    let(:jid) { Digest::MD5.hexdigest('a') }
    let(:error_message) { "#{worker_class} #{jid}" }
    it 'includes worker_class, jid, cause.class and cause.message' do
      expect do
        begin
          raise 'in begin'
        rescue => e
          raise Concerns::WorkerUtils::WorkerError.new worker_class, jid
        end
      end.to raise_error do |ex|
        expect(ex).to be_a(Concerns::WorkerUtils::WorkerError)
        expect(ex.message).to eq(error_message)
        expect(ex.cause).to be_a(RuntimeError)
        expect(ex.full_message).to eq("#{error_message} #{ex.cause.class} #{ex.cause.message}")
      end
    end
  end
end