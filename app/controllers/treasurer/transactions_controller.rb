class Treasurer::TransactionsController < Treasurer::BaseController
  def index
    @transactions = Transaction
      .where(purchaser_type: "Member")
      .where(purchaser_id: current_organization.members.select(:id))
      .or(
        Transaction.where(purchaser_type: "GuestAccess")
          .where(purchaser_id: current_organization.guest_accesses.select(:id))
      )
      .includes(:purchaser, :product)
      .order(created_at: :desc)
      .limit(100)

    if params[:member_id].present?
      @transactions = @transactions.where(purchaser_type: "Member", purchaser_id: params[:member_id])
      @member = current_organization.members.find(params[:member_id])
    end

    @transactions = @transactions.sponsored if params[:sponsored] == "1"
  end

  def new
    @transaction = Transaction.new
    @members = current_organization.members.order(:display_name)
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.organization = current_organization
    if @transaction.save
      redirect_to treasurer_transactions_path, notice: "Transaktion gebucht"
    else
      @members = current_organization.members.order(:display_name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @transaction = find_transaction
    @members = current_organization.members.order(:display_name)
  end

  def update
    @transaction = find_transaction
    if @transaction.update(transaction_params)
      redirect_to treasurer_transactions_path, notice: "Transaktion aktualisiert"
    else
      @members = current_organization.members.order(:display_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    find_transaction.destroy
    redirect_to treasurer_transactions_path, notice: "Transaktion gelöscht"
  end

  private

  def find_transaction
    Transaction.preload(:purchaser).find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:purchaser_type, :purchaser_id, :amount_cents, :kind, :note)
  end
end
