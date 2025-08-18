# frozen_string_literal: true

require 'nacha'
require_relative 'nacha_comparer/version'

module NachaComparer
  class << self
    # Compare two NACHA files and find transfers in the subset file that are missing from the full file
    # 
    # @param subset_file_path [String] Path to the NACHA file containing transfers to verify
    # @param full_file_path [String] Path to the complete NACHA file to search within
    # @return [Hash] Results containing unmatched transfers and summary
    def compare_files(subset_file_path, full_file_path)
      subset_transfers = extract_transfers(subset_file_path)
      full_transfers = extract_transfers(full_file_path)
      
      # Create a lookup hash for efficient searching
      full_transfers_lookup = create_transfer_lookup(full_transfers)
      
      unmatched_transfers = []
      
      subset_transfers.each do |transfer|
        transfer_key = create_transfer_key(transfer)
        unless full_transfers_lookup.key?(transfer_key)
          unmatched_transfers << transfer
        end
      end
      
      {
        total_subset_transfers: subset_transfers.length,
        total_full_file_transfers: full_transfers.length,
        unmatched_count: unmatched_transfers.length,
        matched_count: subset_transfers.length - unmatched_transfers.length,
        unmatched_transfers: unmatched_transfers
      }
    end
    
    private
    
    # Extract transfer information from a NACHA file
    # @param file_path [String] Path to the NACHA file
    # @return [Array<Hash>] Array of transfer hashes
    def extract_transfers(file_path)
      transfers = []
      
      nacha_file = Nacha.parse(file_path)
      current_batch_header = nil
      
      nacha_file.records.each do |record|
        case record.class.name
        when 'Nacha::Record::BatchHeader'
          current_batch_header = record
        when /EntryDetail/
          # Skip if we don't have batch header context
          next unless current_batch_header
          
          # Extract the key transfer information for matching
          record_data = record.to_h
          batch_data = current_batch_header.to_h
          
          transfer = {
            origin_dfi_id: batch_data[:originating_dfi_identification],
            receiving_dfi_id: record_data[:receiving_dfi_identification],
            receiving_account: record_data[:dfi_account_number],
            amount: record_data[:amount],
            transaction_code: record_data[:transaction_code],
            # Additional fields for debugging/reporting
            trace_number: record_data[:trace_number],
            individual_name: record_data[:receiving_company_name]&.strip,
            individual_id: record_data[:identification_number]&.strip,
            batch_number: batch_data[:batch_number],
            service_class_code: batch_data[:service_class_code]
          }
          transfers << transfer
        end
      end
      
      transfers
    rescue => e
      raise "Error parsing NACHA file #{file_path}: #{e.message}"
    end
    
    # Create a lookup hash for efficient transfer matching
    # @param transfers [Array<Hash>] Array of transfer hashes
    # @return [Hash] Lookup hash with transfer keys
    def create_transfer_lookup(transfers)
      lookup = {}
      transfers.each do |transfer|
        key = create_transfer_key(transfer)
        lookup[key] = transfer
      end
      lookup
    end
    
    # Create a unique key for a transfer based on matching criteria
    # @param transfer [Hash] Transfer hash
    # @return [String] Unique key for matching
    def create_transfer_key(transfer)
      "#{transfer[:origin_dfi_id]}-#{transfer[:receiving_dfi_id]}-#{transfer[:receiving_account]}-#{transfer[:amount]}"
    end
  end
end
