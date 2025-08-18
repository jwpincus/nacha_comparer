# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NachaComparer do
  let(:complete_nacha_file) { File.join(__dir__, 'test_complete_nacha_file.txt') }
  let(:subset_nacha_file) { File.join(__dir__, 'test_subset_nacha_file.txt') }
  
  describe '.compare_files' do
    context 'when comparing a file with itself' do
      it 'returns no unmatched transfers' do
        result = NachaComparer.compare_files(complete_nacha_file, complete_nacha_file)
        
        expect(result[:unmatched_count]).to eq(0)
        expect(result[:matched_count]).to eq(result[:total_subset_transfers])
        expect(result[:unmatched_transfers]).to be_empty
      end
    end
    
    context 'when comparing subset file against complete file' do
      it 'finds all subset transfers in the complete file' do
        result = NachaComparer.compare_files(subset_nacha_file, complete_nacha_file)
        
        expect(result[:unmatched_count]).to eq(0)
        expect(result[:matched_count]).to eq(result[:total_subset_transfers])
        expect(result[:total_subset_transfers]).to be < result[:total_full_file_transfers]
        expect(result[:unmatched_transfers]).to be_empty
      end
      
      it 'provides accurate counts' do
        result = NachaComparer.compare_files(subset_nacha_file, complete_nacha_file)
        
        # Subset should have fewer transfers than complete file
        expect(result[:total_subset_transfers]).to be > 0
        expect(result[:total_full_file_transfers]).to be > result[:total_subset_transfers]
        expect(result[:matched_count]).to eq(result[:total_subset_transfers])
      end
    end
    
    context 'when subset file has transfers not in complete file' do
      let(:subset_with_extra) { create_temp_nacha_file_with_extra_transfer }
      
      after { File.delete(subset_with_extra) if File.exist?(subset_with_extra) }
      
      it 'identifies unmatched transfers' do
        result = NachaComparer.compare_files(subset_with_extra, complete_nacha_file)
        
        expect(result[:unmatched_count]).to be > 0
        expect(result[:unmatched_transfers]).not_to be_empty
        expect(result[:total_subset_transfers]).to be > result[:matched_count]
      end
      
      it 'provides details about unmatched transfers' do
        result = NachaComparer.compare_files(subset_with_extra, complete_nacha_file)
        
        unmatched = result[:unmatched_transfers].first
        expect(unmatched).to have_key(:origin_dfi_id)
        expect(unmatched).to have_key(:receiving_dfi_id)
        expect(unmatched).to have_key(:receiving_account)
        expect(unmatched).to have_key(:amount)
        expect(unmatched).to have_key(:individual_name)
      end
    end
    
    context 'with invalid file paths' do
      it 'raises an error for non-existent files' do
        expect do
          NachaComparer.compare_files('nonexistent.txt', complete_nacha_file)
        end.to raise_error(/Error parsing NACHA file/)
      end
    end
  end
  
  describe 'transfer extraction and matching' do
    it 'extracts transfers with correct structure from sample data' do
      transfers = NachaComparer.send(:extract_transfers, complete_nacha_file)
      
      expect(transfers).not_to be_empty
      
      transfer = transfers.first
      expect(transfer).to have_key(:origin_dfi_id)
      expect(transfer).to have_key(:receiving_dfi_id)
      expect(transfer).to have_key(:receiving_account)
      expect(transfer).to have_key(:amount)
      expect(transfer).to have_key(:transaction_code)
      expect(transfer).to have_key(:trace_number)
      expect(transfer).to have_key(:individual_name)
      
      # Verify sample data structure (using sample NACHA file data)
      expect(transfer[:origin_dfi_id]).to eq('02600959')
      expect(transfer[:receiving_dfi_id]).to eq('026009593')
    end
    
    it 'creates consistent transfer keys' do
      transfers = NachaComparer.send(:extract_transfers, complete_nacha_file)
      transfer = transfers.first
      
      key1 = NachaComparer.send(:create_transfer_key, transfer)
      key2 = NachaComparer.send(:create_transfer_key, transfer)
      
      expect(key1).to eq(key2)
      expect(key1).to be_a(String)
      expect(key1.length).to be > 0
    end
    
    it 'extracts different number of transfers from subset vs complete file' do
      subset_transfers = NachaComparer.send(:extract_transfers, subset_nacha_file)
      complete_transfers = NachaComparer.send(:extract_transfers, complete_nacha_file)
      
      expect(subset_transfers.length).to be < complete_transfers.length
      expect(subset_transfers.length).to be > 0
      expect(complete_transfers.length).to be > 0
    end
  end
  
  private
  
  def create_temp_nacha_file_with_extra_transfer
    # Create a temporary NACHA file with an additional fake transfer
    temp_file = File.join(__dir__, 'temp_nacha_test.txt')
    
    # Copy subset file content and add a fake entry
    original_content = File.read(subset_nacha_file)
    
    # Add a fake entry that won't exist in the complete file
    fake_entry = "622888777666555444333        00009999991234567        FAKE TRANSFER COMPANY   9998887776543210\n"
    
    # Insert the fake entry before the batch control record (820 line)
    modified_content = original_content.gsub(
      /^820/,
      "#{fake_entry}820"
    )
    
    File.write(temp_file, modified_content)
    temp_file
  end
end
