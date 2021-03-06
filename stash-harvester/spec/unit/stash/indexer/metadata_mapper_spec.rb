require 'spec_helper'

module Stash
  module Indexer
    describe MetadataMapper do

      describe '#build_from' do
        it 'reads a valid DataciteGeoblacklight config' do
          hash = { metadata_mapping: 'datacite_geoblacklight' }
          mapper = MetadataMapper.build_from(hash)
          expect(mapper).to be_a(DataciteGeoblacklight::Mapper)
        end
      end

      describe '#to_index_document' do
        it 'is abstract' do
          wrapped_metadata = instance_double(Stash::Wrapper::StashWrapper)
          mapper = MetadataMapper.new
          expect { mapper.to_index_document(wrapped_metadata) }.to raise_error(NoMethodError)
        end
      end

      describe '#desc_from' do
        it 'is abstract' do
          mapper = MetadataMapper.new
          expect { mapper.desc_from }.to raise_error(NoMethodError)
        end
      end

      describe '#desc_to' do
        it 'is abstract' do
          mapper = MetadataMapper.new
          expect { mapper.desc_to }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
