require 'rails_helper'

RSpec.describe Musician, type: :model do
  describe 'associations' do
    it { should have_many(:involvements).dependent(:destroy) }
    it { should have_many(:bands).through(:involvements) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'search' do
    let!(:guitarist) { create(:musician, name: 'John Doe', instrument: 'Guitar', location: 'NYC', styles: 'Rock') }
    let!(:bassist) { create(:musician, :bassist, name: 'Jane Smith', location: 'LA', styles: 'Jazz') }
    let!(:drummer) { create(:musician, :drummer, name: 'Bob Brown', location: 'Chicago', styles: 'Metal') }

    describe '.search_by_all' do
      it 'finds musicians by name' do
        results = Musician.search_by_all('John')
        expect(results).to include(guitarist)
        expect(results).not_to include(bassist)
      end

      it 'finds musicians by instrument' do
        results = Musician.search_by_all('Guitar')
        expect(results).to include(guitarist)
        expect(results).not_to include(bassist)
      end

      it 'finds musicians by location' do
        results = Musician.search_by_all('NYC')
        expect(results).to include(guitarist)
        expect(results).not_to include(bassist)
      end

      it 'finds musicians by styles' do
        results = Musician.search_by_all('Jazz')
        expect(results).to include(bassist)
        expect(results).not_to include(guitarist)
      end
    end
  end

  describe 'attachments' do
    it 'can have many attached media files' do
      musician = create(:musician)
      expect(musician.media).to be_an_instance_of(ActiveStorage::Attached::Many)
    end
  end
end
