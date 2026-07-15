class Inventory::InventoryCountsController < Inventory::BaseController
  def index
    @inventory_counts = current_organization.inventory_counts.includes(:product, :member).order(counted_on: :desc)
    @products = current_organization.products.active.order(:name)
  end

  def new
    @inventory_count = current_organization.inventory_counts.new
    @products = current_organization.products.active.order(:name)
  end

  def create
    @inventory_count = current_organization.inventory_counts.new(
      count_params.merge(member: current_member, counted_on: Date.today)
    )
    if @inventory_count.save
      redirect_to inventory_inventory_counts_path, notice: "Inventur gespeichert"
    else
      @products = current_organization.products.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @inventory_count = current_organization.inventory_counts.find(params[:id])
    @inventory_count.destroy

    redirect_to inventory_inventory_counts_path, notice: "Inventur glöscht"
  end
  private

  def count_params
    params.require(:inventory_count).permit(:product_id, :actual_quantity, :note)
  end
end
