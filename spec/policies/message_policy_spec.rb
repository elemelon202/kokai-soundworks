require 'rails_helper'

RSpec.describe MessagePolicy, type: :policy do
  subject { described_class.new(user, message) }

  let(:participant1) { create(:user) }
  let(:participant2) { create(:user) }
  let(:chat) { create(:chat, :direct_message, :with_participants, participants: [participant1, participant2]) }
  let(:message) { create(:message, chat: chat, user: participant1) }

  context 'for a chat participant' do
    let(:user) { participant1 }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:create) }
  end

  context 'for the other participant' do
    let(:user) { participant2 }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:create) }
  end

  context 'for a non-participant' do
    let(:user) { create(:user) }

    it { should forbid_action(:index) }
    it { should forbid_action(:show) }
    it { should forbid_action(:create) }
  end

  context 'for a visitor (no user)' do
    let(:user) { nil }

    it { should forbid_action(:index) }
    it { should forbid_action(:show) }
    it { should forbid_action(:create) }
  end
end
