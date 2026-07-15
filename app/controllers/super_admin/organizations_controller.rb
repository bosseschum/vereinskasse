class SuperAdmin::OrganizationsController < SuperAdmin::BaseController
  def index
    @organizations = Organization.order(:name)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    if @organization.save
      redirect_to super_admin_organizations_path, notice: "#{@organization.name} angelegt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @organization = Organization.find(params[:id])
  end

  def update
    @organization = Organization.find(params[:id])
    if @organization.update(organization_params)
      redirect_to super_admin_organizations_path, notice: "#{@organization.name} aktualisiert"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy
    redirect_to super_admin_organizations_path, notice: "#{@organization.name} gelöscht"
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :active)
  end
end
