class SES::EmailService
  Response = Struct.new(:message_id)

  # Send an email using Resend
  #
  # @param [Hash] params Email parameters
  # @option params [Array<String>] :to Recipient email addresses
  # @option params [String] :from Sender email address
  # @option params [String] :reply_to Reply-to email address
  # @option params [String] :subject Email subject line
  # @option params [String] :html HTML email content
  # @option params [String] :text Plain text email content
  # @option params [Hash<String, String>] :headers Additional email headers
  #
  # @return [Response] Response object with message_id
  def send(params)
    response = Resend::Emails.send(build_email_payload(params))
    Response.new(response[:id])
  end

  private

  def build_email_payload(params)
    {
      from: params[:from],
      to: params[:to],
      reply_to: params[:reply_to],
      subject: params[:subject],
      html: params[:html],
      text: params[:text],
      headers: params.fetch(:headers, {})
    }.compact
  end
end
