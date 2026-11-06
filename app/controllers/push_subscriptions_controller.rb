# Saves or forgets the browser where the current user turned push notifications on or off.
class PushSubscriptionsController < ApplicationController
  # An admin impersonating someone must not get that user's notifications on their own device.
  before_action -> { head :forbidden }, unless: :acting_as_self?

  # The browser sends it again on each visit, so a browser now used by someone else moves to them.
  def create
    attributes = params.expect(push_subscription: [ :endpoint, keys: %i[p256dh auth] ])
    subscription = PushSubscription.find_or_initialize_by(endpoint: attributes[:endpoint])
    subscription.assign_attributes(user: current_user, p256dh_key: attributes.dig(:keys, :p256dh),
                                   auth_key: attributes.dig(:keys, :auth), user_agent: request.user_agent)

    head(subscription.save ? :no_content : :unprocessable_entity)
  end

  def destroy
    current_user.push_subscriptions.where(endpoint: params.expect(:endpoint)).delete_all
    head :no_content
  end
end
