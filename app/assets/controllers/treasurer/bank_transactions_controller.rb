module Treasurer
  class BankTransactionsController < Treasurer::BaseController
    def index
      @connection = current_organization.bank_connection
      @accounts = @connection&.bank_accounts&.includes(:bank_transactions)
      @transactions = @connection
        &.bank_accounts
        &.flat_map(&:bank_transactions)
        &.sort_by { |t| t.booked_at || Date.new(0) }
        &.reverse || []
    end
  end
end
