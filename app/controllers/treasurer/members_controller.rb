class Treasurer::MembersController < Treasurer::BaseController
  def index
    @members = current_organization.members.all.sort_by { |m| m.display_name.split.last.downcase }
  end

  def new
    @member = Member.new
    @membership = @member.organization_memberships.build(organization: current_organization)
  end

  def create
    existing_member = Member.find_by(email: member_params[:email])

    if existing_member
      @member = existing_member
      @membership = @member.organization_memberships.build(
        membership_params.merge(organization: current_organization)
      )

      if @member.organization_memberships.exists?(organization: current_organization)
        @member = Member.new(member_params) # reset for error display
        @member.errors.add(:email, "ist bereits Mitglied in diesem Verein")
        @membership = @member.organization_memberships.build(organization: current_organization)
        return render :new, status: :unprocessable_entity
      end

      if @membership.save
        MemberMailer.welcome(@member, @membership.pin, nil, current_organization).deliver_later
        redirect_to treasurer_members_path, notice: "Mitglied hinzugefügt"
      else
        render :new, status: :unprocessable_entity
      end
    else
      @member = Member.new(member_params)
      @membership = @member.organization_memberships.build(
        membership_params.merge(organization: current_organization)
      )

      if @member.save
        plain_password = @member.generated_password || member_params[:password]
        MemberMailer.welcome(@member, @membership.pin, plain_password, current_organization).deliver_later
        redirect_to treasurer_members_path, notice: "Mitglied angelegt"
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    @member = current_organization.members.find(params[:id])
    @membership = @member.membership_for(current_organization)
  end

  def update
    @member = current_organization.members.find(params[:id])
    @membership = @member.membership_for(current_organization)

    update_params = member_params
    update_params = update_params.except(:password) if update_params[:password].blank?

    membership_update = membership_params
    membership_update = membership_update.except(:pin) if membership_update[:pin].blank?

    if @member.update(update_params) && @membership.update(membership_update)
      redirect_to treasurer_members_path, notice: "Mitglied aktualisiert"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    membership = current_organization.organization_memberships.find_by!(member_id: params[:id])
    membership.destroy
    redirect_to treasurer_members_path, notice: "Mitglied gelöscht"
  end

  def resend_welcome
    @member = current_organization.members.find(params[:id])
    membership = current_organization.organization_memberships.find_by!(member: @member)

    new_password = SecureRandom.hex(8)
    @member.update!(password: new_password)

    MemberMailer.welcome(@member, membership.pin, new_password, current_organization).deliver_later

    redirect_to treasurer_members_path, notice: "Willkommens-E-Mail wurde erneut an #{@member.email} gesendet"
  end

  def send_invoice
    @member = current_organization.members.find(params[:id])
    invoice = Invoice.new(member: @member, organization: current_organization)
    MemberMailer.invoice(@member, current_organization).deliver_later

    redirect_to treasurer_members_path, notice: "Rechnung wurde an #{@member.email} gesendet"
  end

  private

  def member_params
    params.require(:member).permit(:display_name, :email, :password)
  end

  def membership_params
    params.require(:member).require(:organization_membership)
      .permit(:role, :pin, :pays_fee, :lives_on_site)
  end
end
