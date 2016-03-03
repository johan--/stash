module Stash
  module Indexer
    module Solr
      class SolrIndexer < Indexer

        # Creates a new `SolrIndexer`
        # @param metadata_mapper [MetadataMapper] the metadata mapper to convert
        #   harvested documents to indexable documents
        # @param config [SolrIndexConfig] the configuration for this indexer.
        def initialize(metadata_mapper:, config:)
          super(metadata_mapper: metadata_mapper)
          @config = config
        end

        # Indexes the specified records, deleting any deleted records.
        # @param harvested_records [Enumerator::Lazy<HarvestedRecord>] The records to index.
        def index(harvested_records)
          solr = RSolr.connect(@config.opts)
          # TODO: Performance-test this -- is it OK to perform x-thousand add operations?
          harvested_records.each { |r| r.deleted? ? delete_record(r, solr) : index_record(r, solr) }
          solr.commit
        end

        private

        def index_record(r, solr)
          wrapped_metadata = r.content
          index_document = metadata_mapper.to_index_document(wrapped_metadata)
          solr.add index_document
        end

        def delete_record(r, solr)
          solr.delete_by_id r.identifier
        end
      end
    end
  end
end
