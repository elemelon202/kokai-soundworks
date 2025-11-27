require 'rails_helper'

RSpec.describe Gig, type: :model do
  describe 'associations' do
    it { should belong_to(:venue) }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_many(:bands).through(:bookings) }
  end

  describe 'factory' do
    it 'creates a valid gig' do
      gig = build(:gig)
      expect(gig).to be_valid
    end
  end
end
