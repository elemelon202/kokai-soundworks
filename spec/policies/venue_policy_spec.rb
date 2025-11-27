require 'rails_helper'

RSpec.describe VenuePolicy, type: :policy do
  subject { described_class.new(user, venue) }

  let(:owner) { create(:user, user_type: 'venue') }
  let(:venue) { create(:venue, user: owner) }

  context 'for a visitor (no user)' do
    let(:user) { nil }

    it { should forbid_action(:index) }
    it { should permit_action(:show) }
    it { should forbid_action(:new) }
    it { should forbid_action(:edit) }
    it { should forbid_action(:update) }
    it { should forbid_action(:delete) }
  end

  context 'for the venue owner' do
    let(:user) { owner }

    it { should forbid_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:new) }
    it { should permit_action(:edit) }
    it { should permit_action(:update) }
    it { should permit_action(:delete) }
  end

  context 'for another venue user' do
    let(:user) { create(:user, user_type: 'venue') }

    it { should forbid_action(:index) }
    it { should permit_action(:show) }
    it { should permit_action(:new) }
    it { should forbid_action(:edit) }
    it { should forbid_action(:update) }
    it { should forbid_action(:delete) }
  end

  context 'for a non-venue user' do
    let(:user) { create(:user, user_type: 'musician') }

    it { should forbid_action(:index) }
    it { should permit_action(:show) }
    it { should forbid_action(:new) }
    it { should forbid_action(:edit) }
    it { should forbid_action(:update) }
    it { should forbid_action(:delete) }
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let!(:venue1) { create(:venue, user: user) }
    let!(:venue2) { create(:venue) }

    it 'returns all venues' do
      scope = Pundit.policy_scope(user, Venue)
      expect(scope).to include(venue1, venue2)
    end
  end
end
