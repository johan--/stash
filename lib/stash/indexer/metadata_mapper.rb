require 'config/factory'
require 'stash/wrapper'

module Stash
  module Indexer

    # Superclass of installation-specific mappers converting wrapped metadata to
    # indexable documents.
    class MetadataMapper
      include ::Config::Factory

      key :metadata_mapping

      attr_reader :opts

      def initialize(*opts)
        @opts = opts
      end

      # Converts a Stash-wrapped metadata document to an indexable document.
      #
      # @param wrapped_metadata [StashWrapper] a Stash-wrapped metadata document with
      #   appropriate descriptive elements for this mapper.
      # @return [Object] a document extracting information from `wrapped_metadata`
      #   and formatting it appropriately for the index supported by this mapper.
      def to_index_document(wrapped_metadata) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #to_index_document to map wrapped metadata to indexable documents, but it doesn't"
      end
    end
  end
end
