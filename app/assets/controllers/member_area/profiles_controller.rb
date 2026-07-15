class MemberArea::ProfilesController < MemberArea::BaseController
  def show
    @member = current_member
  end

  def edit
    @member = current_member
  end

  def update
    @member = current_member
    update_params = {}

    if params[:member][:pin].present?
      if params[:member][:pin].length == 4 && params[:member][:pin].match?(/\A\d+\z/)
        update_params[:pin] = params[:member][:pin]
      else
        @member.errors.add(:pin, "muss genau 4 Ziffern haben")
        render :edit, status: :unprocessable_entity and return
      end
    end

    if params[:member][:password].present?
      if params[:member][:password] == params[:member][:password_confirmation]
        update_params[:password] = params[:member][:password]
      else
        @member.errors.add(:password_confirmation, "muss mit dem Passwort übereinstimmen")
        render :edit, status: :unprocessable_entity and return
      end
    end

    if update_params.empty? || @member.update(update_params)
      redirect_to member_area_profile_path, notice: "Profil erfolgreich aktualisiert"
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
