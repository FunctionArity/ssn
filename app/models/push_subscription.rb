# A browser or phone where a user turned on push notifications (Web Push).
# The browser gives us the endpoint, on its push service, and the keys to encrypt what we send there.
class PushSubscription < ApplicationRecord
  # The server POSTs to the endpoint, so only the browsers' own push services are accepted:
  # Chrome and Android, Firefox, Safari and iPhone, Edge.
  PUSH_SERVICE_HOSTS = %w[fcm.googleapis.com push.services.mozilla.com push.apple.com notify.windows.com].freeze

  belongs_to :user

  validates :endpoint, :p256dh_key, :auth_key, presence: true
  validate :endpoint_on_push_service

  # The VAPID keys identify this server to the push services. Without them nothing is sent.
  def self.vapid
    @vapid ||= {
      subject: "mailto:#{Devise.mailer_sender[/[^<\s]+@[^>\s]+/]}",
      public_key: Rails.application.credentials.dig(:vapid, :public_key) || ENV["VAPID_PUBLIC_KEY"],
      private_key: Rails.application.credentials.dig(:vapid, :private_key) || ENV["VAPID_PRIVATE_KEY"]
    }
  end

  def self.enabled?
    vapid[:public_key].present? && vapid[:private_key].present?
  end

  # Sends the notification; a subscription the push service no longer knows is deleted.
  # message: { title:, options: { body:, data: { path: } } }, as the service worker shows it.
  def deliver(message)
    WebPush.payload_send(message: message.to_json, endpoint: endpoint, p256dh: p256dh_key, auth: auth_key,
                         vapid: self.class.vapid, ttl: 1.day.to_i, urgency: "high")
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    destroy
  end

  private

  def endpoint_on_push_service
    uri = URI.parse(endpoint.to_s)
    host = uri.host.to_s
    return if uri.scheme == "https" && PUSH_SERVICE_HOSTS.any? { |allowed| host == allowed || host.end_with?(".#{allowed}") }

    errors.add(:endpoint, :invalid)
  rescue URI::InvalidURIError
    errors.add(:endpoint, :invalid)
  end
end
