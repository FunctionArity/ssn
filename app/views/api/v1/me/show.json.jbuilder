json.token @token if @token
json.user do
  json.partial! "api/v1/user", user: current_user
  json.extract! current_user, :email, :user_type
  json.can_switch_headquarter current_user.super_admin?
end
json.headquarter do
  json.partial! "api/v1/headquarters/headquarter", headquarter: current_headquarter
end
