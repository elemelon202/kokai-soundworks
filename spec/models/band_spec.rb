require 'rails_helper'

RSpec.describe Band, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_many(:gigs).through(:bookings) }
    it { should have_many(:involvements).dependent(:destroy) }
    it { should have_many(:musicians).through(:involvements) }
    it { should have_many(:band_invitations).dependent(:destroy) }
    it { should have_one(:chat).dependent(:destroy) }
    it { should have_many(:messages).through(:chat) }
  end

  describe 'callbacks' do
    describe '#setup_band_membership_and_chat' do
      let(:user) { create(:user) }

      context 'when user has no musician profile' do
        it 'creates a musician profile for the user' do
          expect {
            create(:band, user: user)
          }.to change(Musician, :count).by(1)
        end

        it 'sets the musician name to the username' do
          band = create(:band, user: user)
          expect(user.reload.musician.name).to eq(user.username)
        end
      end

      context 'when user has a musician profile' do
        let!(:musician) { create(:musician, user: user) }

        it 'does not create a new musician profile' do
          expect {
            create(:band, user: user)
          }.not_to change(Musician, :count)
        end

        it 'uses the existing musician profile' do
          band = create(:band, user: user)
          expect(band.musicians).to include(musician)
        end
      end

      it 'adds the creator as a band member' do
        band = create(:band, user: user)
        expect(band.musicians.count).to eq(1)
        expect(band.musicians.first.user).to eq(user)
      end

      it 'creates a chat for the band' do
        band = create(:band, user: user)
        expect(band.chat).to be_present
        expect(band.chat.name).to eq("#{band.name} Chat")
      end

      it 'adds the creator as a chat participant' do
        band = create(:band, user: user)
        expect(band.chat.users).to include(user)
      end
    end
  end

  describe 'scopes' do
    describe '.with_genres' do
      let!(:rock_band) { create(:band) }
      let!(:jazz_band) { create(:band) }

      before do
        rock_band.genre_list.add('Rock')
        rock_band.save
        jazz_band.genre_list.add('Jazz')
        jazz_band.save
      end

      it 'returns bands with matching genres' do
        expect(Band.with_genres(['Rock'])).to include(rock_band)
        expect(Band.with_genres(['Rock'])).not_to include(jazz_band)
      end
    end
  end

  describe 'tagging' do
    it 'can be tagged with genres' do
      band = create(:band)
      band.genre_list.add('Rock', 'Jazz')
      band.save!

      expect(band.reload.genre_list).to include('Rock', 'Jazz')
    end
  end

  describe 'constants' do
    it 'has a list of genres' do
      expect(Band::GENRES).to include('Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop')
    end
  end
end
