class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :validatable, :lockable, :trackable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

  # A user works in one sede. Users are still found by email across sedes when they sign in.
  acts_as_tenant :headquarter

  has_one_attached :avatar, service: :amazon_avatar

  enum :role, { guardian: 0, vocal: 1, priest: 2 }, default: :guardian
  enum :user_type, { regular: 0, admin: 1, super_admin: 2 }, default: :regular

  # Secrets and IPs are never stored; Devise sign-in tracking and invitation bookkeeping alone don't create a version.
  # Invitations themselves live in devise_invitations since devise_invitable 3.
  has_paper_trail \
    skip: %i[encrypted_password reset_password_token unlock_token remember_created_at current_sign_in_ip last_sign_in_ip],
    ignore: %i[updated_at sign_in_count current_sign_in_at last_sign_in_at failed_attempts reset_password_sent_at
               invitation_limit invitations_count]

  default_scope { order(:last_name, :first_name) }

  validates :first_name, :last_name, presence: true

  scope :guardians, -> { where(role: :guardian) }
  scope :vocals, -> { where(role: :vocal) }
  scope :priests, -> { where(role: :priest) }
  scope :priests_without_setup, -> { priests.where.not(id: PriestSetup.select(:priest_id)) }
  scope :grouped_by_role, -> { order(:last_name, :first_name).group_by(&:role) }
  scope :recent_logins, -> { where(last_sign_in_at: 15.days.ago..).order(last_sign_in_at: :desc).limit(20) }
  scope :search_by_name, ->(query) {
    sanitized = "%#{sanitize_sql_like(query)}%"
    where("first_name ILIKE :q OR last_name ILIKE :q", q: sanitized)
  }
  # Users who can sign in, leaving out pending invitations and locked accounts.
  scope :mentionable, -> { no_active_invitation.where(locked_at: nil) }
  scope :without_password, -> { where(encrypted_password: [ nil, "" ]) }
  # Users of every sede, not just the current one: super admins work in any sede, so the author of a comment, a
  # reaction, a service or a change may be from another one. Also the scope of associations to those authors.
  scope :in_any_sede, -> { unscope(where: :headquarter_id) }

  # The authors of the given PaperTrail versions, by id as a string, the way versions keep it.
  def self.authors_of(versions)
    in_any_sede.where(id: versions.filter_map(&:whodunnit).uniq).index_by { |user| user.id.to_s }
  end

  belongs_to :church, optional: true

  has_many :guard_guardians, dependent: :destroy
  has_many :guards, through: :guard_guardians

  has_many :vocal_guard_setups, class_name: "GuardSetup", foreign_key: :vocal_id, dependent: :nullify, inverse_of: :vocal

  has_many :guard_setup_guardians, dependent: :destroy

  has_many :comments, dependent: :destroy
  has_many :comment_mentions, dependent: :destroy
  has_many :push_subscriptions, dependent: :delete_all
  has_many :comment_reactions, dependent: :delete_all
  has_many :guard_setups, through: :guard_setup_guardians

  attr_accessor :guard_setup_day_number

  after_save :move_to_guard_setup, if: -> { guard_setup_day_number.present? }

  def role_badge_class
    case role
    when "guardian" then "badge_green"
    when "vocal"    then "badge_red"
    when "priest"   then "badge_purple"
    end
  end

  def role_icon_class
    case role
    when "guardian" then "ph-user"
    when "vocal"    then "ph-user-circle"
    when "priest"   then "ph-cross"
    end
  end

  def role_icon_color_class
    case role
    when "guardian" then "text-green-600"
    when "vocal"    then "text-red-600"
    when "priest"   then "text-purple-600"
    end
  end

  # Can't sign in until they accept an invitation: invited and not accepted yet, or without a password of their own.
  # Lists preload devise_invitations so this doesn't query once per user.
  def pending_activation?
    encrypted_password.blank? || awaiting_invitation_acceptance?
  end

  # Never accepted an invitation nor signed in, so sending one is how they get in.
  def invitation_needed?
    !invitation_accepted? && last_sign_in_at.nil?
  end

  # devise_invitable only treats an invitation as "provisioning" if it originally created the resource, so
  # resending one to a user who's still passwordless isn't provisioning by its definition - it would strip
  # the password params on acceptance, assuming (wrongly, here) that the resource is already active.
  def resource_previously_provisioned?
    super && encrypted_password.present?
  end

  # The user Google signed in, by the email Google verified. Accounts are only made by invitation, so an
  # email without one finds nobody. Locked users and pending invitations are then refused by Devise.
  def self.from_google(auth)
    with_verified_google_email(auth.info.email, auth.extra.raw_info.email_verified)
  end

  # Same, from the claims of a Google ID token (One Tap).
  def self.from_google_id_token(claims)
    with_verified_google_email(claims["email"], claims["email_verified"])
  end

  def self.with_verified_google_email(email, verified)
    return unless email.present? && verified.to_s == "true"

    find_by(email: email.downcase)
  end
  private_class_method :with_verified_google_email

  # Mentions of the user in comments of the current sede, newest first, with what the mentions page shows of each.
  def recent_mentions
    comment_mentions.in_current_sede
                    .includes(comment: %i[user commentable])
                    .order(created_at: :desc, id: :desc)
  end

  # Comments of the current sede that mention the user and they haven't read: the number on the bell in the top nav.
  def unread_mentions
    comment_mentions.in_current_sede.unread
  end

  def full_name
    "#{last_name} #{first_name}"
  end

  def initials
    "#{last_name[0]}#{first_name[0]}"
  end

  def guard_day_numbers
    (vocal_guard_setups + guard_setups).map(&:day_number).uniq.sort
  end

  def self.current_priest(date = Date.current)
    if date.day >= 28
      PriestSetup.where(day_of_month: date.day).first&.priest
    else
      week_day = ((date.wday - 1) % 7) + 1
      week_month = week_of_month(date)
      PriestSetup.find_priest_by_week_and_day(week_day, week_month)
    end
  end

  def self.week_of_month(date)
    bom = date.beginning_of_month
    first_occurrence = bom + ((date.cwday - bom.cwday) % 7)
    ((date - first_occurrence) / 7).floor + 1
  end

  private

  # Same as devise_invitable's invitation_pending?, but answered from the preloaded invitations when there are any.
  def awaiting_invitation_acceptance?
    return invitation_pending? unless devise_invitations.loaded?

    devise_invitations.any? { |invitation| invitation.pending? && invitation.provisioning? }
  end

  def move_to_guard_setup
    MoveUserToGuardSetupService.new(self, guard_setup_day_number).call
  end
end
