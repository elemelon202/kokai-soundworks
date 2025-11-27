require 'rails_helper'

RSpec.describe Venue, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:gigs).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid venue' do
      venue = build(:venue)
      expect(venue).to be_valid
    end
  end

  describe 'attachments' do
    it 'can have many attached photos' do
      venue = create(:venue)
      expect(venue.photos).to be_an_instance_of(ActiveStorage::Attached::Many)
    end
  end
end
