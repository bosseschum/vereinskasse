module Banking
  class CallbacksController < ApplicationController
    skip_before_action :authenticate_member!
    skip_before_action :set_organization

    def show
      if params[:error].present?
        Rails.logger.error("Enable Banking callback error: #{params[:error]}")
        return redirect_to root_path, alert: "Bankverbindung fehlgeschlagen: #{params[:error]}"
      end

      code = params[:code]
      return redirect_to root_path, alert: "Fehlender Autorisierungscode." if code.blank?

      begin
        session_data = EnableBanking::Client.new.post("/sessions", { code: code })
      rescue RuntimeError => e
        Rails.logger.error("Enable Banking session exchange failed: #{e.message}")
        return redirect_to root_path, alert: "Bankverbindung konnte nicht hergestellt werden."
      end

      connection = BankConnection.find_by(authorization_id: params[:state])
      unless connection
        Rails.logger.error("No BankConnection found for state: #{params[:state]}")
        return redirect_to root_path, alert: "Sitzung nicht gefunden."
      end

      connection.update!(session_id: session_data["session_id"])

      session_data["accounts"].each do |account|
        connection.bank_accounts.find_or_create_by!(uid: account["uid"]) do |a|
          a.iban     = account.dig("account_id", "iban")
          a.product  = account["product"]
          a.currency = account["currency"] || "EUR"
        end
      end

      begin
        EnableBanking::TransactionSyncService.new(connection).call
      rescue RuntimeError => e
        Rails.logger.error("Transaction sync failed after connect: #{e.message}")
        # Don't fail the whole flow — accounts are saved, sync will retry
      end

      org = connection.organization
      redirect_to treasurer_bank_transactions_url(
        host: "#{org.subdomain}.#{Rails.application.config.default_url_options[:host]}"
      ), allow_other_host: true, notice: "Bank verbunden — #{connection.bank_accounts.count} Konten importiert."
    end
  end
end
