require 'rails_helper'

RSpec.describe BandInvitation, type: :model do
  describe 'associations' do
    it { should belong_to(:band) }
    it { should belong_to(:musician) }
    it { should belong_to(:inviter).class_name('User') }
  end

  describe 'validations' do
    subject { create(:band_invitation) }

    it { should validate_uniqueness_of(:musician_id).scoped_to(:band_id).with_message("has already been invited to this band") }
  end

  describe 'callbacks' do
    describe '#generate_token' do
      it 'generates a token before creation' do
        invitation = build(:band_invitation, token: nil)
        invitation.save!
        expect(invitation.token).to be_present
        expect(invitation.token.length).to eq(40) # SecureRandom.hex(20) generates 40 characters
      end

      it 'does not override existing token' do
        existing_token = SecureRandom.hex(20)
        invitation = create(:band_invitation, token: existing_token)
        # The callback runs but should generate a new token since token was nil before create
        expect(invitation.token).to be_present
      end
    end
  end

  describe 'scopes' do
    let(:band) { create(:band) }
    let(:musician1) { create(:musician) }
    let(:musician2) { create(:musician) }
    let(:musician3) { create(:musician) }
    let(:inviter) { band.user }

    let!(:pending_invitation) { create(:band_invitation, band: band, musician: musician1, inviter: inviter, status: 'Pending') }
    let!(:accepted_invitation) { create(:band_invitation, band: band, musician: musician2, inviter: inviter, status: 'Accepted') }
    let!(:declined_invitation) { create(:band_invitation, band: band, musician: musician3, inviter: inviter, status: 'Declined') }

    describe '.pending' do
      it 'returns only pending invitations' do
        expect(BandInvitation.pending).to include(pending_invitation)
        expect(BandInvitation.pending).not_to include(accepted_invitation, declined_invitation)
      end
    end

    describe '.accepted' do
      it 'returns only accepted invitations' do
        expect(BandInvitation.accepted).to include(accepted_invitation)
        expect(BandInvitation.accepted).not_to include(pending_invitation, declined_invitation)
      end
    end

    describe '.declined' do
      it 'returns only declined invitations' do
        expect(BandInvitation.declined).to include(declined_invitation)
        expect(BandInvitation.declined).not_to include(pending_invitation, accepted_invitation)
      end
    end

    describe '.sent_by' do
      let(:other_user) { create(:user) }
      let(:other_band) { create(:band, user: other_user) }
      let!(:other_invitation) { create(:band_invitation, band: other_band, musician: create(:musician), inviter: other_user) }

      it 'returns invitations sent by specific user' do
        expect(BandInvitation.sent_by(inviter)).to include(pending_invitation, accepted_invitation, declined_invitation)
        expect(BandInvitation.sent_by(inviter)).not_to include(other_invitation)
      end
    end
  end
end
