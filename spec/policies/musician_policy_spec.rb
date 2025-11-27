require 'rails_helper'

RSpec.describe MusicianPolicy, type: :policy do
  subject { described_class.new(user, musician) }

  let(:musician_user) { create(:user) }
  let(:musician) { create(:musician, user: musician_user) }

  context 'for a visitor (no user)' do
    let(:user) { nil }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should forbid_action(:update) }
  end

  context 'for the musician owner' do
    let(:user) { musician_user }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:update) }
  end

  context 'for another user' do
    let(:user) { create(:user) }

    it { should permit_action(:index) }
    it { should permit_action(:show) }
    it { should forbid_action(:update) }
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let!(:musician1) { create(:musician, user: user) }
    let!(:musician2) { create(:musician) }

    it 'returns all musicians' do
      scope = Pundit.policy_scope(user, Musician)
      expect(scope).to include(musician1, musician2)
    end
  end
end
