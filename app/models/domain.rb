# == Schema Information
#
# Table name: domains
#
#  id               :bigint           not null, primary key
#  dkim_status      :string           default("pending")
#  dmarc_added      :boolean          default(FALSE)
#  error_message    :string
#  name             :string
#  public_key       :string
#  region           :string           default("us-east-1")
#  resend_records   :jsonb
#  spf_status       :string           default("pending")
#  status           :string           default("pending")
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  newsletter_id    :bigint           not null
#  resend_domain_id :string
#
# Indexes
#
#  index_domains_on_name                                   (name) UNIQUE
#  index_domains_on_newsletter_id                          (newsletter_id)
#  index_domains_on_status_and_dkim_status_and_spf_status  (status,dkim_status,spf_status)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class Domain < ApplicationRecord
  belongs_to :newsletter

  enum :status, %w[ not_started pending success failed temporary_failure ].index_by(&:itself), default: :pending, prefix: true
  enum :dkim_status, %w[ not_started pending success failed temporary_failure ].index_by(&:itself), default: :pending, prefix: true
  enum :spf_status, %w[ pending success failed temporary_failure ].index_by(&:itself), default: :pending, prefix: true

  validates :name, presence: true, uniqueness: true

  scope :verified, -> { where(status: :success, dkim_status: :success, spf_status: :success) }

  def verified?
    status_success? && dkim_status_success? && spf_status_success?
  end

  def register
    response = ses_service.create_identity
    dkim_record = response[:records]&.find { |r| r[:record] == "DKIM" }
    update(
      resend_domain_id: response[:id],
      resend_records: response[:records],
      region: response[:region],
      public_key: dkim_record&.dig(:value)
    )
    sync_attributes
  end

  def register_or_sync
    if resend_domain_id.nil?
      register
    else
      sync_attributes
    end
  end

  def drop_identity
    ses_service.delete_identity
  end

  def self.claimed_by_other?(name, newsletter_id)
    where(name: name)
      .where.not(newsletter_id: newsletter_id)
      .where(
        "(status = ? OR dkim_status = ? OR spf_status = ?)",
        "success", "success", "success"
      ).exists?
  end

  def verify
    sync_attributes
    verified?
  end

  private

  def sync_attributes
    identity = ses_service.get_identity
    dkim_record = identity[:records]&.find { |r| r[:record] == "DKIM" }
    spf_record = identity[:records]&.find { |r| r[:record] == "SPF" && r[:type] == "TXT" }
    update(
      resend_records: identity[:records],
      dkim_status: map_resend_status(dkim_record&.dig(:status)),
      spf_status: map_resend_status(spf_record&.dig(:status)),
      status: map_resend_status(identity[:status])
    )
  end

  def map_resend_status(resend_status)
    case resend_status
    when "verified" then "success"
    when "not_started", nil then "pending"
    else resend_status
    end
  end

  def ses_service
    @ses_service ||= SES::DomainService.new(name, resend_domain_id: resend_domain_id)
  end
end
