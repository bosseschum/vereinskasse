class Inventory::DashboardController < Inventory::BaseController
  def index
    @products = current_organization.products.active.order(:name)
  end
end
