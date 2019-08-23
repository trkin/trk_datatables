$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'trk_datatables'

# from gems
require 'minitest/autorun'
require 'minitest/color'
require 'byebug'
require 'database_cleaner'

# our config stuff
require 'config_support/active_record_helper.rb'
require 'config_support/database_cleaner.rb'

# our runtime support
require 'runtime_support/assert_with_message.rb'
