class Inventory::BaseController < ApplicationController
  layout "inventory"
  before_action :require_inventory_manager!

  private

  def require_inventory_manager!
    unless current_member&.inventory_manager?(current_organization)
      redirect_to root_path, alert: "Kein Zugriff"
    end
  end
end
