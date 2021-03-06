# frozen_string_literal: true

require_dependency 'stash_api/application_controller'
require_relative 'datasets/submission_mixin'

module StashApi
  class DatasetsController < ApplicationController

    include SubmissionMixin

    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[show download update]
    before_action :doorkeeper_authorize!, only: %i[create update]
    before_action :require_api_user, only: %i[create update]
    before_action :set_last_resource, only: :update
    # before_action :require_in_progress_resource, only: :update
    before_action :require_permission, only: :update

    # rubocop:disable Metrics/AbcSize
    # get /datasets/<id>
    def show
      ds = Dataset.new(identifier: @stash_identifier.to_s)
      respond_to do |format|
        format.json { render json: ds.metadata }
        format.xml { render xml: ds.metadata.to_xml(root: 'dataset') }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
        res = @stash_identifier.last_submitted_resource
        StashEngine::CounterLogger.general_hit(request: request, resource: res) if res
      end
    end
    # rubocop:enable Metrics/AbcSize

    # post /datasets
    def create
      respond_to do |format|
        format.json do
          dp = DatasetParser.new(hash: params['dataset'], id: nil, user: @user)
          @stash_identifier = dp.parse
          ds = Dataset.new(identifier: @stash_identifier.to_s) # sets up display objects
          render json: ds.metadata, status: 201
        end
      end
    end

    # get /datasets
    def index
      datasets = paged_datasets
      respond_to do |format|
        format.json { render json: datasets }
        format.xml { render xml: datasets.to_xml(root: 'datasets') }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # we are using PATCH only to update the versionStatus=submitted
    # PUT will be to update/replace the dataset metadata
    # put/patch /datasets/<id>
    def update
      do_patch { return } # check if patch and do submission and return early if it is a patch (submission)
      # otherwise this is a PUT of the dataset metadata
      check_status { return } # check it's in progress, clone a submitted or raise an error
      respond_to do |format|
        format.json do
          dp = DatasetParser.new(hash: params['dataset'], id: @resource.identifier, user: @user)
          @stash_identifier = dp.parse
          ds = Dataset.new(identifier: @stash_identifier.to_s) # sets up display objects
          render json: ds.metadata, status: 200
        end
      end
    end

    # get /datasets/<id>/download
    def download
      res = @stash_identifier.last_submitted_resource
      if res&.download_uri
        res = @stash_identifier.last_submitted_resource
        StashEngine::CounterLogger.version_download_hit(request: request, resource: res) if res
        redirect_to res.merritt_producer_download_uri # latest version, friendly download because that's what we do in UI for object
      else
        render text: 'download for this dataset is unavailable', status: 404
      end
    end

    private

    def do_patch # rubocop:disable Metrics/AbcSize
      return unless request.method == 'PATCH' && request.headers['content-type'] == 'application/json-patch+json'
      check_patch_prerequisites { yield }
      check_dataset_completions { yield }
      pre_submission_updates
      StashEngine.repository.submit(resource_id: @resource.id)
      # render something
      ds = Dataset.new(identifier: @stash_identifier.to_s)
      render json: ds.metadata, status: 202
      yield
    end

    def check_status
      state = @resource.current_resource_state.try(:resource_state)
      return if state == 'in_progress'
      return_error(messages: 'Your dataset cannot be updated now', status: 403) { yield } if state != 'submitted'
      duplicate_resource # because we're starting a new version
    end

    def duplicate_resource
      nr = @resource.amoeba_dup
      nr.current_editor_id = @user.id
      nr.save!
      @resource = nr
    end

    def all_datasets
      { 'stash:datasets' =>
          StashEngine::Identifier.all.map { |i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata } }
    end

    def paged_datasets # rubocop:disable Metrics/AbcSize
      all_count = StashEngine::Identifier.all.count
      results = StashEngine::Identifier.all.limit(page_size).offset(page_size * (page - 1))
      results = results.map { |i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata }
      paging_hash_results(all_count, results)
    end

    def paging_hash_results(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:datasets' => results }
      }
    end

  end
end
