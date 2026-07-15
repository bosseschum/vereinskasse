class SuperAdmin::DashboardController < SuperAdmin::BaseController
  def index
    @organizations = Organization.order(:name)
  end
end
