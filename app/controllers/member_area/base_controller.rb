class MemberArea::BaseController < ApplicationController
  layout "member_area"
  before_action :require_member!

  private

  def require_member!
    unless current_member
      redirect_to new_member_session_path, alert: "Bitte einloggen."
    end
  end
end
