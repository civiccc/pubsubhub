require 'coveralls'
Coveralls.wear!

require 'pubsubhub'

RSpec.configure do |config|
  # order matters: `treat_symbols_as_metadata_keys_with_true_values` must come
  # before `filter_run`
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus

  config.mock_with :mocha
  config.order = 'random'
  config.run_all_when_everything_filtered = true
end
