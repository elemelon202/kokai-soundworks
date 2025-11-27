require 'rails_helper'

RSpec.describe ChatPolicy, type: :policy do
  subject { described_class.new(user, chat) }

  let(:participant1) { create(:user) }
  let(:participant2) { create(:user) }
  let(:chat) { create(:chat, :direct_message, :with_participants, participants: [participant1, participant2]) }

  context 'for a chat participant' do
    let(:user) { participant1 }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:create) }
    it { should permit_action(:create_or_show) }
  end

  context 'for a non-participant' do
    let(:user) { create(:user) }

    it { should permit_action(:index) }
    it { should forbid_action(:show) }
    it { should permit_action(:create) }
    it { should permit_action(:create_or_show) }
  end

  context 'for a visitor (no user)' do
    let(:user) { nil }

    it { should permit_action(:index) }
    it { should forbid_action(:show) }
    it { should permit_action(:create) }
    it { should permit_action(:create_or_show) }
  end

  describe 'Scope' do
    let(:user) { participant1 }
    let!(:other_chat) { create(:chat, :direct_message, :with_participants, participants: [create(:user), create(:user)]) }

    it 'returns only chats the user participates in' do
      scope = Pundit.policy_scope(user, Chat)
      expect(scope).to include(chat)
      expect(scope).not_to include(other_chat)
    end
  end
end
