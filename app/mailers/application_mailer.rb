class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  private

  def notify_address
    "Hyperbulletin Notifications <notifications@#{sending_domain}>"
  end

  def accounts_address
    "Hyperbulletin Accounts <accounts@#{sending_domain}>"
  end

  def support_address
    "Hyperbulletin Support <support@#{sending_domain}>"
  end

  def alerts_address
    "Hyperbulletin Alerts <alerts@#{sending_domain}>"
  end

  def sending_domain
    AppConfig.get("PICO_SENDING_DOMAIN", "hyperbulletin.com")
  end
end
