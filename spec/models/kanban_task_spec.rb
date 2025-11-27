require 'rails_helper'

RSpec.describe KanbanTask, type: :model do
  describe 'associations' do
    it { should belong_to(:created_by).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:task_type) }
    it { should validate_presence_of(:created_by) }
    it { should validate_inclusion_of(:status).in_array(KanbanTask::STATUSES) }
    it { should validate_inclusion_of(:task_type).in_array(KanbanTask::TASK_TYPES) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:todo_task) { create(:kanban_task, status: 'to_do', created_by: user) }
    let!(:in_progress_task) { create(:kanban_task, :in_progress, created_by: user) }
    let!(:review_task) { create(:kanban_task, :in_review, created_by: user) }
    let!(:done_task) { create(:kanban_task, :done, created_by: user) }

    describe '.by_status' do
      it 'filters tasks by status' do
        expect(KanbanTask.by_status('to_do')).to include(todo_task)
        expect(KanbanTask.by_status('to_do')).not_to include(in_progress_task, review_task, done_task)
      end
    end

    describe '.by_type' do
      let!(:rehearsal_task) { create(:kanban_task, task_type: 'rehearsal', created_by: user) }
      let!(:recording_task) { create(:kanban_task, task_type: 'recording', created_by: user) }

      it 'filters tasks by type' do
        expect(KanbanTask.by_type('rehearsal')).to include(rehearsal_task)
        expect(KanbanTask.by_type('rehearsal')).not_to include(recording_task)
      end
    end

    describe '.overdue' do
      let!(:overdue_task) { create(:kanban_task, :overdue, created_by: user) }
      let!(:future_task) { create(:kanban_task, deadline: Date.today + 7.days, created_by: user) }
      let!(:done_overdue_task) { create(:kanban_task, deadline: Date.today - 1.day, status: 'done', created_by: user) }

      it 'returns tasks with deadline in the past that are not done' do
        expect(KanbanTask.overdue).to include(overdue_task)
        expect(KanbanTask.overdue).not_to include(future_task, done_overdue_task)
      end
    end

    describe '.upcoming' do
      let!(:upcoming_task) { create(:kanban_task, :upcoming, created_by: user) }
      let!(:far_future_task) { create(:kanban_task, deadline: Date.today + 30.days, created_by: user) }
      let!(:past_task) { create(:kanban_task, deadline: Date.today - 1.day, created_by: user) }

      it 'returns tasks with deadline within the next 7 days' do
        expect(KanbanTask.upcoming).to include(upcoming_task)
        expect(KanbanTask.upcoming).not_to include(far_future_task, past_task)
      end
    end

    describe '.ordered' do
      let!(:task1) { create(:kanban_task, position: 2, created_by: user) }
      let!(:task2) { create(:kanban_task, position: 1, created_by: user) }
      let!(:task3) { create(:kanban_task, position: 1, created_at: 1.day.ago, created_by: user) }

      it 'orders by position ascending, then by created_at descending' do
        ordered = KanbanTask.ordered
        expect(ordered.index(task2)).to be < ordered.index(task1)
      end
    end
  end

  describe 'constants' do
    it 'has valid statuses' do
      expect(KanbanTask::STATUSES).to eq(%w[to_do in_progress review done])
    end

    it 'has valid task types' do
      expect(KanbanTask::TASK_TYPES).to include('rehearsal', 'recording', 'mixing', 'booking')
    end
  end
end
