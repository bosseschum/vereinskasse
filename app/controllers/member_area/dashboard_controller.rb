class MemberArea::DashboardController < MemberArea::BaseController
  def index
    @member = current_member
    @transactions = @member.transactions.order(created_at: :desc).limit(20)
    @requests = @member.requests.order(created_at: :desc).limit(5)
  end
end
