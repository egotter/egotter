require 'rails_helper'

RSpec.describe Logging do
  controller ApplicationController do
    include Logging
  end

  describe '#track_event' do
    subject { controller.track_event('name', 'properties') }
    it do
      expect(controller).to receive_message_chain(:ahoy, :track).with('name', 'properties')
      subject
    end
  end

  describe '#track_sign_in_event' do
    subject { controller.track_sign_in_event(context: 'c', via: 'v') }
    it do
      expect(controller).to receive_message_chain(:ahoy, :track).with('Sign in', via: 'v')
      subject
    end
  end

  describe '#find_referral' do
    subject { controller.send(:find_referral, %w(http://t.co/aaa http://egotter.com)) }
    it { is_expected.to eq('t.co') }
  end

  describe '#find_channel' do
    subject { controller.send(:find_channel, 't.co') }
    it { is_expected.to eq('twitter') }
  end
end
