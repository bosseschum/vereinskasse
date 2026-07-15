class Inventory::ProductsController < Inventory::BaseController
  def index
    @products = current_organization.products.order(:name)
  end

  def new
    @product = current_organization.products.new
  end

  def create
    @product = current_organization.products.new(product_params)
    if @product.save
      redirect_to inventory_products_path, notice: "Produkt angelegt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = current_organization.products.find(params[:id])
  end

  def update
    @product = current_organization.products.find(params[:id])
    if @product.update(product_params)
      redirect_to inventory_products_path, notice: "Produkt aktualisiert"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :price_cents, :active, :crate_size, :crate_price_cents)
  end
end
