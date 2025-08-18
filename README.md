# NachaComparer

A Ruby gem for comparing NACHA (ACH) files to verify that transfers from  are present in a larger file. This is particularly useful for financial reconciliation processes where you need to ensure that disbursements from a float account are accurately reflected in the bank's transaction records.

## Features

- Compare transfers between two NACHA files
- Verify that all transfers in a subset file exist in a complete file
- Match on origin account, destination account, and transfer amount
- Detailed reporting of matched and unmatched transfers
- Built on the reliable `nacha` gem for NACHA file parsing

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nacha_comparer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install nacha_comparer

## Usage

### Basic Comparison

```ruby
require 'nacha_comparer'

# Compare transfers from a float account file against a complete bank file
result = NachaComparer.compare_files('float_transfers.txt', 'complete_bank_file.txt')

puts "Total transfers in subset: #{result[:total_subset_transfers]}"
puts "Matched transfers: #{result[:matched_count]}"
puts "Unmatched transfers: #{result[:unmatched_count]}"

# Display any unmatched transfers
result[:unmatched_transfers].each do |transfer|
  puts "Unmatched: #{transfer[:receiving_dfi_id]}/#{transfer[:receiving_account]}, Amount: $#{transfer[:amount]/100.0}"
end
```

### Return Value Structure

The `compare_files` method returns a hash with the following structure:

```ruby
{
  total_subset_transfers: 3,      # Number of transfers in the subset file
  total_full_file_transfers: 5,   # Number of transfers in the complete file  
  matched_count: 3,               # Number of transfers that matched
  unmatched_count: 0,             # Number of transfers that didn't match
  unmatched_transfers: [          # Array of unmatched transfer details
    {
      origin_dfi_id: "02600959",
      receiving_dfi_id: "026009593", 
      receiving_account: "1234",
      amount: 5335,  # Amount in cents
      transaction_code: 27,
      trace_number: 26009590000001,
      individual_name: nil,  # May be nil for some record types
      individual_id: nil,    # May be nil for some record types
      batch_number: 1,
      service_class_code: 200
    }
    # ... more unmatched transfers
  ]
}
```

## Matching Criteria

The comparer matches transfers based on:

1. **Origin DFI ID** - The originating depository financial institution
2. **Receiving DFI ID** - The receiving depository financial institution  
3. **Receiving Account Number** - The destination account number
4. **Amount** - The transfer amount (in cents)

## Use Cases

- **Float Account Reconciliation**: Verify that disbursements from a float account appear in the bank's complete transaction file
- **Transfer Verification**: Ensure specific transfers are properly recorded in bank files
- **Audit Trail**: Create detailed reports of missing or unmatched transfers
- **Financial Controls**: Automated verification as part of financial processing workflows

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/nacha_comparer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Dependencies

- [nacha](https://github.com/dwilkins/nacha) - Ruby ACH parser for reading NACHA files
