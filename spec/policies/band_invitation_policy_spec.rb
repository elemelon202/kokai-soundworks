require 'rails_helper'

RSpec.describe BandInvitationPolicy, type: :policy do
  subject { described_class.new(user, invitation) }

  let(:band_owner) { create(:user) }
  let(:band) { create(:band, user: band_owner) }
  let(:invited_user) { create(:user) }
  let(:invited_musician) { create(:musician, user: invited_user) }
  let(:invitation) { create(:band_invitation, band: band, musician: invited_musician, inviter: band_owner) }

  context 'for the band owner (inviter)' do
    let(:user) { band_owner }

    it { should permit_action(:create) }
    it { should forbid_action(:accept) }
    it { should forbid_action(:decline) }
  end

  context 'for the invited musician' do
    let(:user) { invited_user }

    it { should forbid_action(:create) }
    it { should permit_action(:accept) }
    it { should permit_action(:decline) }
  end

  context 'for a random user' do
    let(:user) { create(:user) }

    it { should forbid_action(:create) }
    it { should forbid_action(:accept) }
    it { should forbid_action(:decline) }
  end

  context 'for a visitor (no user)' do
    let(:user) { nil }

    it { should forbid_action(:create) }
    it { should forbid_action(:accept) }
    it { should forbid_action(:decline) }
  end

  describe 'Scope' do
    let(:user) { band_owner }
    let!(:other_invitation) { create(:band_invitation) }

    it 'returns all invitations' do
      scope = Pundit.policy_scope(user, BandInvitation)
      expect(scope).to include(invitation, other_invitation)
    end
  end
end
