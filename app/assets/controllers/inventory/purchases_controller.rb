class Inventory::PurchasesController < Inventory::BaseController
  def index
    @purchases = current_organization.purchases.includes(:product, :member).order(purchased_on: :desc)
  end

  def new
    @purchase = current_organization.purchases.new
    @products = current_organization.products.active.order(:name)
  end

  def create
    @purchase = current_organization.purchases.new(purchase_params.merge(member: current_member))
    if @purchase.save
      redirect_to inventory_purchases_path, notice: "Einkauf erfasst"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @purchase = current_organization.purchases.find(params[:id])
    @products = current_organization.proucts.active.order(:name)
  end

  def update
    @purchase = current_organization.purchases.find(params[:id])

    if @purchase.update(purchase_params)
      redirect_to inventory_purchases_path, notice: "Einkauf aktualisiert"
    else
      @products = current_organization.products.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase = current_organization.purchases.find(params[:id])
    @purchase.destroy

    redirect_to inventory_purchases_path, notice: "Einkauf gelöscht"
  end

  private

  def purchase_params
    params.require(:purchase).permit(
      :product_id, :quantity, :price_per_unit_cents, :purchased_on, :note
    )
  end
end
