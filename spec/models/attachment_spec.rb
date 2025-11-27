require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'associations' do
    it { should belong_to(:message) }
  end

  describe 'factory' do
    it 'creates a valid attachment' do
      attachment = build(:attachment)
      expect(attachment).to be_valid
    end
  end
end
