require "trk_datatables/version"
# modules
require "trk_datatables/preferences"
require "trk_datatables/base_helpers"
require "trk_datatables/base"
require "trk_datatables/active_record"
require "trk_datatables/neo4j"
require "trk_datatables/dt_params"
require "trk_datatables/column_key_options"
require "trk_datatables/render_html"

# libs
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/string/output_safety"
require "active_support/core_ext/time/zones"

# we need to define here since some conventions will look for definition in this file
module TrkDatatables
  class Error < StandardError
    def message
      "TrkDatatables: #{super}"
    end
  end
end
