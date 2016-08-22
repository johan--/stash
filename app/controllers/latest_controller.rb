# -*- encoding : utf-8 -*-
require 'blacklight/controller'
require 'blacklight/catalog'

class LatestController < ApplicationController
  helper_method :current_tenant, :current_user, :metadata_engine, :metadata_url_helpers, :stash_url_helpers,
                :current_tenant_simple, :logo_path

  helper StashEngine::ApplicationHelper

  include StashEngine::SharedController

  include Blacklight::Controller
  include Blacklight::Catalog
  layout 'stash_engine/application'

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
        :start => 0,
        :rows => 20,
        'q.alt' => '*:*',
        :sort => 'timestamp desc'
    }

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
        :qt => 'document',
        :q => '{!raw f=uuid v=$id}'
    }

    config.search_builder_class = Geoblacklight::SearchBuilder

    # solr field configuration for search results/index views
    # config.index.show_link = 'title_display'
    # config.index.record_display_type = 'format'

    config.index.title_field = 'dc_title_s'

    # solr field configuration for document/show views

    config.show.display_type_field = 'format'

    # Custom GeoBlacklight fields which currently map to GeoBlacklight-Schema
    # v0.3.2
    config.wxs_identifier_field = 'layer_id_s'



    # solr fields to be displayed in the show (single result) view
    #  The ordering of the field names is the order of the display
    #
    # item_prop: [String] property given to span with Schema.org item property
    # link_to_search: [Boolean] that can be passed to link to a facet search
    # helper_method: [Symbol] method that can be used to render the value
    config.add_show_field 'dc_creator_sm', label: 'Author(s)', itemprop: 'author'
    config.add_show_field 'dc_description_s', label: 'Description', itemprop: 'description', helper_method: :render_value_as_truncate_abstract
    config.add_show_field 'dc_publisher_s', label: 'Publisher', itemprop: 'publisher'
    config.add_show_field 'dct_isPartOf_sm', label: 'Collection', itemprop: 'isPartOf'
    config.add_show_field 'dct_spatial_sm', label: 'Place(s)', itemprop: 'spatial', link_to_search: true
    config.add_show_field 'dc_subject_sm', label: 'Subject(s)', itemprop: 'keywords', link_to_search: true
    config.add_show_field 'dct_temporal_sm', label: 'Year', itemprop: 'temporal'
    config.add_show_field 'dct_provenance_s', label: 'Held by', link_to_search: true

  end

  # get search results from the solr index
  def index
    (@response, @document_list) = search_results(params, search_params_logic)

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.js
      format.json do
        render json: render_search_results_as_json
      end
    end
  end

end