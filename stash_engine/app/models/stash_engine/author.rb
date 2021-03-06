module StashEngine
  class Author < ActiveRecord::Base

    include StashEngine::Concerns::ResourceUpdated

    belongs_to :resource, class_name: 'StashEngine::Resource'

    EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

    validates :author_email, format: EMAIL_REGEX, allow_blank: true

    before_save :strip_whitespace

    scope :names_filled, -> { where("TRIM(IFNULL(author_first_name,'')) <> ''") }

    amoeba do
      enable
    end

    def author_full_name
      [author_last_name, author_first_name].reject(&:blank?).join(', ')
    end

    def author_standard_name
      "#{author_first_name} #{author_last_name}".strip
    end

    def author_html_email_string
      return if author_email.blank?
      "<a href=\"mailto:#{CGI.escapeHTML(author_email.strip)}\">#{CGI.escapeHTML(author_standard_name.strip)}</a>"
    end

    def affiliation_by_name(name)
      affils = StashDatacite::Affiliation.where(['short_name = ? OR long_name = ? or abbreviation = ?', name, name, name])
      affil =
        if affils.count > 0
          affils.first
        else
          StashDatacite::Affiliation.create(long_name: name)
        end
      affiliations << affil
    end

    # NOTE: this ONLY works b/c we assume that only the resource-owning
    # user can set their own ORCiD
    def init_user_orcid
      return unless author_orcid
      return unless (user = resource.user)
      return if user.orcid

      user.orcid = author_orcid
      user.save
    end
    after_save :init_user_orcid

    private

    def strip_whitespace
      self.author_first_name = author_first_name.strip if author_first_name
      self.author_last_name = author_last_name.strip if author_last_name
      self.author_email = author_email.strip if author_email
      self.author_orcid = nil if author_orcid.blank?
    end
  end
end
