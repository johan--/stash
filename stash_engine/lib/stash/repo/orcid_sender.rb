require 'securerandom'

module Stash
  module Repo
    class OrcidSender
      #creates orcid invitation info and
      def initialize(resource)
        @resource = resource
        @identifier = @resource.identifier
      end

      def deliver_invitations!
        authors = @resource.authors.where.not(author_email: nil)
        authors.each do |author|
          next if author.author_email.blank? || StashEngine::OrcidInvitation.where(email: author.author_email).where(identifier_id: @identifier.id).count > 0
          invite = StashEngine::OrcidInvitation.create(
            email: author.author_email,
            identifier_id: @identifier.id,
            first_name: author.author_first_name,
            last_name: author.author_last_name,
            secret: SecureRandom.hex(16),
            invited_at: Time.new
          )
          StashEngine::UserMailer.orcid_invitation(invite).deliver_now
        end
      end
    end
  end
end