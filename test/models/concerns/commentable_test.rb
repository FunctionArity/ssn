require "test_helper"

class CommentableTest < ActiveSupport::TestCase
  test "records users comment on have comments" do
    service = services(:one)
    comment = service.comments.create!(user: users(:one), body: "<p>Visto</p>")

    assert_equal [ comment ], service.comments.to_a
  end

  test "a commentable model must name its records in notifications" do
    model = Class.new(ApplicationRecord) do
      self.table_name = "services"
      include Commentable
    end

    assert_raises(NotImplementedError) { model.new.comment_subject }
  end
end
