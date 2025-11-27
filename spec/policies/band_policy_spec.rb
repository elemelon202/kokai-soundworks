require 'rails_helper'

RSpec.describe BandPolicy, type: :policy do
  subject { described_class.new(user, band) }

  let(:owner) { create(:user) }
  let(:band) { create(:band, user: owner) }

  context 'for a visitor (no user)' do
    let(:user) { nil }

    it { should permit_action(:show) }
    it { should forbid_action(:create) }
    it { should forbid_action(:new) }
    it { should forbid_action(:edit) }
    it { should forbid_action(:update) }
    it { should forbid_action(:destroy) }
  end

  context 'for the band owner' do
    let(:user) { owner }

    it { should permit_action(:show) }
    it { should permit_action(:create) }
    it { should permit_action(:new) }
    it { should permit_action(:edit) }
    it { should permit_action(:update) }
    it { should permit_action(:destroy) }
  end

  context 'for a band member (non-owner)' do
    let(:member_user) { create(:user) }
    let(:member_musician) { create(:musician, user: member_user) }
    let(:user) { member_user }

    before do
      create(:involvement, band: band, musician: member_musician)
    end

    it { should permit_action(:show) }
    it { should permit_action(:create) }
    it { should permit_action(:new) }
    it { should permit_action(:edit) }
    it { should permit_action(:update) }
    it { should forbid_action(:destroy) }
  end

  context 'for a random authenticated user' do
    let(:user) { create(:user) }

    it { should permit_action(:show) }
    it { should permit_action(:create) }
    it { should permit_action(:new) }
    it { should forbid_action(:edit) }
    it { should forbid_action(:update) }
    it { should forbid_action(:destroy) }
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let!(:band1) { create(:band, user: user) }
    let!(:band2) { create(:band) }

    it 'returns all bands' do
      scope = Pundit.policy_scope(user, Band)
      expect(scope).to include(band1, band2)
    end
  end
end
