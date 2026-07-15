class Treasurer::DashboardController < Treasurer::BaseController
  def index
    @members = current_organization.members.all.sort_by { |m| m.display_name.split.last.downcase }
  end
end
