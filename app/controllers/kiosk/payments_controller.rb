class Kiosk::PaymentsController < ApplicationController
  skip_before_action :authenticate_member!

  def show
    @member   = current_organization.members.find(params[:id])
    @amount   = @member.balance_cents.abs
    org       = current_organization

    # Verwendungszweck mit Platzhaltern
    reference_template = Setting.get("payment_reference",
      "Bierrechnung {monat}/{jahr} {name}", organization: org)
    @reference = reference_template
      .gsub("{name}",  @member.display_name)
      .gsub("{monat}", Date.current.month.to_s.rjust(2, "0"))
      .gsub("{jahr}",  Date.current.year.to_s)

    # Bank-QR (EPC/Girocode) — nur wenn IBAN hinterlegt
    @bank_iban = Setting.get("bank_iban", "", organization: org)
    @bank_name = Setting.get("bank_name", "", organization: org)
    @bank_bic  = Setting.get("bank_bic",  "", organization: org)

    if @bank_iban.present?
      girocode_data = [
        "BCD", "002", "1", "SCT",
        @bank_bic,
        @bank_name,
        @bank_iban,
        "EUR#{format("%.2f", @amount / 100.0)}",
        "",
        @reference,
        ""
      ].join("\n")
      @bank_qr = RQRCode::QRCode.new(girocode_data)
    end

    # PayPal — nur wenn aktiviert und Username hinterlegt
    paypal_enabled  = Setting.get("payment_method_paypal", "false", organization: org) == "true"
    @paypal_username = Setting.get("paypal_me_username", "", organization: org)

    if paypal_enabled && @paypal_username.present?
      amount_formatted = format("%.2f", @amount / 100.0)
      @paypal_url = "https://paypal.me/#{@paypal_username}/#{amount_formatted}EUR"
      @paypal_qr  = RQRCode::QRCode.new(@paypal_url)
    end
  end
end
