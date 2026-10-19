require "test_helper"

class SmsActivableTest < ActiveSupport::TestCase
  setup do
    User.delete_all
    @user = User.create!(email: "client@example.com", password: "password123", phone: "5551234567")
  end

  test "confirm_by_sms_token confirms a token sent within sms_confirm_within" do
    @user.update_columns(sms_confirmation_token: "ABCDE", confirmation_sms_sent_at: 1.minute.ago)

    result = User.confirm_by_sms_token("ABCDE")

    assert_empty result.errors
    assert @user.reload.confirmed_sms?
  end

  test "confirm_by_sms_token rejects a token older than sms_confirm_within" do
    @user.update_columns(sms_confirmation_token: "ABCDE", confirmation_sms_sent_at: 30.days.ago)

    result = User.confirm_by_sms_token("ABCDE")

    assert_includes result.errors.details[:sms_confirmation_token], { error: :expired }
    refute @user.reload.confirmed_sms?
    assert_equal "ABCDE", @user.sms_confirmation_token
  end

  # confirmation_sms_sent_at also starts the sign-in grace period in active_for_authentication?
  test "send_sms_token cannot extend the sign-in grace period" do
    @user.update_columns(sms_confirmation_token: "ABCDE", confirmation_sms_sent_at: 30.days.ago)
    refute @user.reload.active_for_authentication?

    @user.send_sms_token

    refute @user.reload.active_for_authentication?
  end

  test "send_sms_token resends a token that has not expired" do
    @user.update_columns(sms_confirmation_token: "ABCDE", confirmation_sms_sent_at: 1.minute.ago)

    @user.send_sms_token

    assert_equal "ABCDE", @user.reload.sms_confirmation_token
  end
end
