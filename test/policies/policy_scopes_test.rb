require "test_helper"

# Policies whose scope doesn't narrow the records: each user already only sees their own sede's.
class PolicyScopesTest < ActiveSupport::TestCase
  {
    ChurchPolicy => Church,
    GuardPolicy => Guard,
    HeadquarterPolicy => Headquarter,
    HealthFacilityPolicy => HealthFacility,
    ServicePolicy => Service,
    UserPolicy => User
  }.each do |policy, model|
    test "#{policy} scope has every #{model.model_name.human(count: 2, locale: :en)}" do
      assert_equal model.ids.sort, policy::Scope.new(users(:one), model).resolve.ids.sort
    end
  end
end
