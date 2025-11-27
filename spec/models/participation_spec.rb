require 'rails_helper'

RSpec.describe Participation, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:chat) }
  end

  describe 'factory' do
    it 'creates a valid participation' do
      participation = build(:participation)
      expect(participation).to be_valid
    end
  end
end
