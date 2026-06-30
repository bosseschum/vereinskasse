class Transaction < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :purchaser, polymorphic: true
  belongs_to :product, optional: true

  scope :sponsored, -> { where(sponsored: true) }
  scope :not_sponsored, -> { where(sponsored: false).or(where(sponsored: nil)) }

  enum :kind, {
    drink_purchase: 0,
    deposit: 1,
    expense_reimbursement: 2,
    membership_fee: 3,
    manual_charge: 4
  }

  before_validation :set_default_quantity

  validates :amount_cents, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  KIND_LABELS = {
    "drink_purchase" => "Trinkauf",
    "deposit" => "Einzahlung",
    "expense_reimbursement" => "Ausgaben",
    "membership_fee" => "Mitgliedsgebühr",
    "manual_charge" => "Manuelle Ausgabe"
  }.freeze

  def kind_label
    KIND_LABELS[kind] || kind
  end

  def member
    purchaser if purchaser_type == "Member"
  end

  def guest
    purchaser if purchaser_type == "GuestAccess"
  end

  private

  def set_default_quantity
    self.quantity ||= 1
  end
end
