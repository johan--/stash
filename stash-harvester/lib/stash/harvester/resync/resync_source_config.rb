require 'stash/harvester/source_config'

module Stash
  module Harvester
    module Resync

      # The configuration of a ResourceSync data source.
      class ResyncSourceConfig < SourceConfig

        protocol 'Resync'

        # Constructs a new {ResyncSourceConfig} for resources described by
        # the specified Capability List.
        #
        # @param capability_list_url [URI, String] the URL of the capability list.
        #   *(Required)*
        # @raise [URI::InvalidURIError] if `capability_list_url` is a string that is not a valid URI
        def initialize(capability_list_url:)
          super(source_url: capability_list_url)
        end

        def create_harvest_task(from_time: nil, until_time: nil)
          ResyncHarvestTask.new(config: self, from_time: from_time, until_time: until_time)
        end

      end
    end
  end
end
