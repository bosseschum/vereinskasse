class Treasurer::RequestsController < Treasurer::BaseController
  def index
    @requests = Request.joins(member: :organization_memberships)
      .where(organization_memberships: { organization: current_organization })
      .includes(:member)
      .order(created_at: :desc)
  end

  def show
    @request = find_request
  end

  def destroy
    @request = find_request
    @request.destroy!
    redirect_to treasurer_requests_path, notice: "Antrag gelöscht"
  end

  def approve
    @request = find_request
    kind = @request.expense? ? :expense_reimbursement : :deposit

    @request.update!(status: :approved)
    MemberMailer.request_approved(@request, current_organization).deliver_later
    redirect_to treasurer_requests_path, notice: "Antrag genehmigt"
  end

  def reject
    @request = find_request
    @request.update!(status: :rejected, note: params[:note])
    MemberMailer.request_rejected(@request, current_organization).deliver_later
    redirect_to treasurer_requests_path, notice: "Antrag abgelehnt"
  end

  private

  def find_request
    Request.joins(member: :organization_memberships)
      .where(organization_memberships: { organization: current_organization })
      .find(params[:id])
  end
end
