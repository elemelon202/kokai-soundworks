require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should belong_to(:band) }
    it { should belong_to(:gig) }
  end

  describe 'factory' do
    it 'creates a valid booking' do
      booking = build(:booking)
      expect(booking).to be_valid
    end
  end
end
