class Treasurer::SettingsController < Treasurer::BaseController
  def show
    @settings = {
      fee_standard_cents: Setting.get("fee_standard_cents", 2500, organization: current_organization).to_i,
      fee_resident_cents: Setting.get("fee_resident_cents", 2500, organization: current_organization).to_i,
      bank_name: Setting.get("bank_name", "", organization: current_organization),
      bank_iban: Setting.get("bank_iban", "", organization: current_organization),
      bank_bic: Setting.get("bank_bic", "", organization: current_organization),
      invoice_date: Setting.get("invoice_date", 1, organization: current_organization),
      payment_reference: Setting.get("payment_reference", "Bierrechnung {monat}/{jahr} {name}", organization: current_organization),
      payment_method_paypal: Setting.get("payment_method_paypal", "false", organization: current_organization),
      paypal_me_username: Setting.get("paypal_me_username", "", organization: current_organization)
    }
  end

  def update
    params[:settings].each do |key, value|
      Setting.set(key, value, organization: current_organization)
    end
    redirect_to treasurer_settings_path, notice: "Einstellungen gespeichert"
  end
end
