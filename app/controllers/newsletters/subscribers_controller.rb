require "csv"

class Newsletters::SubscribersController < ApplicationController
  include NewsletterScoped
  layout "newsletters"

  before_action :ensure_authenticated
  before_action :set_newsletter
  before_action :set_subscriber, only: [ :show, :update, :destroy, :unsubscribe, :send_reminder ]


  def index
    status = params[:status] || "verified"

    @pagy, @subscribers = pagy(@newsletter.subscribers
      .order(created_at: :desc)
      .where(status: status), limit: 30)
  end

  def show
  end

  def destroy
    @subscriber.destroy!
    redirect_to subscribers_url(@newsletter.slug), notice: "Subscriber deleted successfully"
  end

  def update
    @subscriber.update!(subscriber_params)
    # redirect to show with notice
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "Subscriber updated successfully"
  end

  def unsubscribe
    @subscriber.unsubscribe!
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "#{@subscriber.display_name} has been unsubscribed."
  end

  def send_reminder
    @subscriber.send_reminder
    redirect_to subscriber_url(@newsletter.slug, @subscriber.id), notice: "Reminder sent."
  end

  def export
    subscribers = @newsletter.subscribers.order(:created_at)
    csv = CSV.generate(headers: true) do |csv|
      csv << [ "email", "full_name", "labels", "status", "created_at" ]
      subscribers.each do |s|
        csv << [ s.email, s.full_name, s.labels.join(";"), s.status, s.created_at.iso8601 ]
      end
    end
    send_data csv, filename: "subscribers-#{Date.today}.csv", type: "text/csv"
  end

  def import
    file = params[:file]
    return redirect_to subscribers_path(@newsletter.slug), notice: "Please select a CSV file." unless file

    results = { imported: 0, skipped: 0, errors: [] }
    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      email = row[:email]&.strip
      next results[:skipped] += 1 if email.blank?

      subscriber = @newsletter.subscribers.find_or_initialize_by(email: email.downcase)
      if subscriber.new_record?
        subscriber.full_name = row[:full_name]&.strip
        subscriber.labels    = row[:labels]&.split(";")&.map(&:strip) || []
        subscriber.status    = :verified
        subscriber.created_via = "import"
        if subscriber.save
          results[:imported] += 1
        else
          results[:errors] << "#{email}: #{subscriber.errors.full_messages.to_sentence}"
        end
      else
        results[:skipped] += 1
      end
    end

    notice = "Imported #{results[:imported]} subscriber(s), skipped #{results[:skipped]} duplicate(s)."
    notice += " Errors: #{results[:errors].join(', ')}" if results[:errors].any?
    redirect_to subscribers_path(@newsletter.slug), notice: notice
  end

  private

  def set_subscriber
    @subscriber = @newsletter.subscribers.find(params[:id])
  end

  def subscriber_params
    params.require(:subscriber).permit(:email, :full_name, :notes)
  end
end
