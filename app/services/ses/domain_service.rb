class SES::DomainService
  def initialize(domain, resend_domain_id: nil)
    @domain = domain
    @resend_domain_id = resend_domain_id
  end

  def create_identity
    Resend::Domains.create(name: @domain)
  end

  def get_identity
    Resend::Domains.get(@resend_domain_id)
  end

  def delete_identity
    return unless @resend_domain_id

    Resend::Domains.remove(@resend_domain_id)
  end
end
