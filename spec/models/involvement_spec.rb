require 'rails_helper'

RSpec.describe Involvement, type: :model do
  describe 'associations' do
    it { should belong_to(:band) }
    it { should belong_to(:musician) }
  end

  describe 'validations' do
    # Need to create a valid involvement first, but we need to avoid the band callback
    # that automatically creates an involvement for the band creator
    let(:user) { create(:user) }
    let(:band) { create(:band, user: user) }
    let(:musician) { create(:musician) }

    it 'validates uniqueness of musician_id scoped to band_id' do
      create(:involvement, band: band, musician: musician)
      duplicate = build(:involvement, band: band, musician: musician)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:musician_id]).to include("is already in this band")
    end
  end

  describe 'callbacks' do
    describe '#add_user_to_band_chat' do
      let(:band_owner) { create(:user) }
      let(:band) { create(:band, user: band_owner) }
      let(:musician) { create(:musician) }

      it 'adds the musician user to the band chat' do
        expect {
          create(:involvement, band: band, musician: musician)
        }.to change { band.chat.users.count }.by(1)
      end

      it 'creates a participation for the musician user' do
        involvement = create(:involvement, band: band, musician: musician)
        expect(band.chat.users).to include(musician.user)
      end

      it 'does not create duplicate participations' do
        create(:participation, user: musician.user, chat: band.chat)
        expect {
          create(:involvement, band: band, musician: musician)
        }.not_to change { Participation.count }
      end
    end
  end
end
