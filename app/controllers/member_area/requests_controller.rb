class MemberArea::RequestsController < MemberArea::BaseController
  def index
    @requests = current_member.requests.order(created_at: :desc)
  end

  def show
    @request = current_member.requests.find(params[:id])
  end

  def new
    @request = current_member.requests.new
  end

  def create
    @request = current_member.requests.new(request_params)
    if @request.save
      TreasurerMailer.new_request(@request, current_organization).deliver_later
      redirect_to member_area_requests_path, notice: "Antrag eingereicht!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def request_params
    params.require(:request).permit(:kind, :description, :amount_cents, receipts: [])
  end
end
