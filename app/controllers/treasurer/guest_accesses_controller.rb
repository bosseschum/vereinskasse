class Treasurer::GuestAccessesController < Treasurer::BaseController
  def index
    @guests = current_organization.guest_accesses.order(created_at: :desc)
  end

  def new
    @guest = GuestAccess.new
  end

  def create
    @guest = current_organization.guest_accesses.new(guest_access_params)
    if @guest.save
      redirect_to treasurer_guest_accesses_path, notice: "Gastzugang erstellt - PIN: #{@guest.pin}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def send_invoice
    @guest = current_organization.guest_accesses.find(params[:id])

    if @guest.transactions.empty?
      redirect_to treasurer_guest_accesses_path,
        alert: "Keine Buchungen vorhanden" and return
    end

    GuestMailer.invoice(@guest).deliver_later
    @guest.update!(invoiced: true)

    redirect_to treasurer_guest_accesses_path,
      notice: "Rechnung an #{@guest.email} gesendet"
  end

  private

  def guest_access_params
    params.require(:guest_access).permit(:display_name, :email, :expires_at)
  end
end
