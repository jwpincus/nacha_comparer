# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'nacha_comparer'
  spec.version       = '0.1.0'
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  spec.summary       = 'Compare NACHA files to verify float account transfers are present in complete bank files.'
  spec.description   = 'A Ruby gem for comparing NACHA (ACH) files to verify that transfers from a float account are present in a larger file. Useful for financial reconciliation processes where you need to ensure that disbursements from a float account are accurately reflected in bank transaction records.'
  spec.homepage      = 'https://github.com/yourusername/nacha_comparer'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb'] + ['README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.add_dependency 'nacha'

  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
