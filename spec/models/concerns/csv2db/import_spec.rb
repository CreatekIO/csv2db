require 'spec_helper'

RSpec.describe Csv2db::Import do
  class TestModel < ActiveRecord::Base
    include Csv2db::Import
    self.table_name = 'csv_imports'
  end

  subject do
    TestModel.new(
      file: Tempfile.new(['content', '.csv'])
    )
  end

  describe '#param' do
    it 'can set a parameter' do
      user_id = rand(1.99)
      subject.param(:user_id, user_id)
      expect(subject.param(:user_id)).to eq(user_id)
    end

    it 'can set a param using the param_... magic method' do
      user_id = rand(1.99)
      subject.param_user_id = user_id
      expect(subject.param_user_id).to eq(user_id)
    end
  end

  describe '#summary_item' do
    it 'can set a summary item' do
      subject.summary_item('Transactions', 545)
      subject.summary_item('Points', 600)
      subject.summary_item('Total value', '£40000')

      expect(subject.summary).to include(name: 'Transactions', value: 545, category: '')
    end
  end

  describe '#summary_categories' do
    it 'returns all the categories' do
      subject.summary_item('User Transactions', 100, 'Transactions')
      subject.summary_item('Total Transactions', 200, 'Transactions')
      subject.summary_item('User Points', 600, 'Points')

      expect(subject.summary_categories).to include('Transactions', 'Points')
      expect(subject.summary_categories.count).to eq(2)
    end
  end

  describe '#summary_items_for_category' do
    it 'returns all the items' do
      subject.summary_item('User Transactions', 100, 'Transactions')
      subject.summary_item('Total Transactions', 200, 'Transactions')
      subject.summary_item('User Points', 600, 'Points')

      items = subject.summary_items_for_category('Transactions')
      expect(items).to include(name: 'User Transactions', value: 100, category: 'Transactions')
      expect(items.count).to eq(2)
    end
  end

  describe '#process' do
    before do
      allow(subject.file).to receive(:ext).and_return('csv')
      allow(subject).to receive(:check_headers)
    end

    it 'should change status to completed if there are no errors' do
      allow(subject).to receive(:process_file) {}
      subject.process
      expect(subject.status).to eq(described_class::Status::COMPLETED)
    end

    it 'should change status to failed if there are' do
      allow(subject).to receive(:process_file) { subject.send(:log, 'An error message', :error) }
      subject.process
      expect(subject.status).to eq(described_class::Status::FAILED)
    end

    it 'should change status to aborted if an exception is raised' do
      allow(subject).to receive(:process_file) { raise 'Custom Error' }
      subject.process
      expect(subject.status).to eq(described_class::Status::ABORTED)
    end
  end

  describe '#pending?' do
    it 'should return true if the status is pending' do
      subject.status = described_class::Status::PENDING
      expect(subject.pending?).to be_truthy
    end

    it 'should return true if the status is pending' do
      subject.status = described_class::Status::COMPLETED
      expect(subject.pending?).to be_falsey
    end
  end

  describe '#errors?' do
    it 'should return true if there are errors' do
      expect(subject.errors?).to be_falsey
      subject.send(:log, 'Some error', :error)
      expect(subject.errors?).to be_truthy
    end
  end
end
