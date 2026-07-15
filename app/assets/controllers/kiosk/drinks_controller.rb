class Kiosk::DrinksController < ApplicationController
  skip_before_action :authenticate_member!

  def index
    @products = current_organization.products.active.order(:name)

    if params[:pin].present?
      membership = current_organization.organization_memberships
        .find_by(pin: params[:pin])
      guest = current_organization.guest_accesses
        .active.find_by(pin: params[:pin])

      @purchaser = membership&.member || guest
      @pin_verified = @purchaser.present?

      flash.now[:alert] = "Unbekannte PIN" unless @pin_verified
    end

    if @purchaser && @pin_verified
      @cart = session[:cart] ||= {}
      @cart_items = @cart.map do |product_id, quantity|
        { product: current_organization.products.find(product_id), quantity: quantity }
      end
      @total_quantity = @cart_items.sum { |i| i[:quantity] }
      @is_mixed_crate = @total_quantity == CRATE_SIZE
      @cart_total = if @is_mixed_crate
        CRATE_PRICE_CENTS
      else
        @cart_items.sum { |i| i[:product].price_cents * i[:quantity] }
      end
    end
  end

  def add_to_cart
    session[:cart] ||= {}
    product_id = params[:product_id].to_s
    quantity   = params[:quantity].to_i
    session[:cart][product_id] = (session[:cart][product_id] || 0) + quantity
    redirect_to kiosk_root_path(pin: params[:pin])
  end

  def remove_from_cart
    session[:cart] ||= {}
    session[:cart].delete(params[:product_id].to_s)
    redirect_to kiosk_root_path(pin: params[:pin])
  end

  def checkout
    membership = current_organization.organization_memberships
      .find_by(pin: params[:pin])
    guest = current_organization.guest_accesses
      .active.find_by(pin: params[:pin])

    @purchaser = membership&.member || guest
    cart        = session[:cart] || {}
    sponsored   = params[:sponsored] == "1"

    unless @purchaser
      redirect_to kiosk_root_path, alert: "Unbekannte PIN" and return
    end

    if cart.empty?
      redirect_to kiosk_root_path(pin: params[:pin]),
        alert: "Warenkorb ist leer" and return
    end

    total_quantity = cart.values.sum
    is_mixed_crate = total_quantity == CRATE_SIZE

    einzelpreis_gesamt = cart.sum do |pid, qty|
      current_organization.products.find(pid).price_cents * qty
    end

    total = is_mixed_crate ? CRATE_PRICE_CENTS : einzelpreis_gesamt

    # Saldo-Check gilt nur für Members, nicht für Gäste (Gäste bekommen Rechnung)
    if @purchaser.is_a?(Member) && !@purchaser.can_purchase?(sponsored ? 0 : total)
      redirect_to kiosk_root_path(pin: params[:pin]),
        alert: "Saldo zu niedrig (Limit: -50€)" and return
    end

    cart.each do |product_id, quantity|
      product = current_organization.products.find(product_id)
      actual_amount = product.price_cents * quantity

      Transaction.create!(
        purchaser:             @purchaser,
        product:               product,
        amount_cents:          sponsored ? 0 : -actual_amount,
        original_amount_cents: actual_amount,
        kind:                  :drink_purchase,
        quantity:              quantity,
        sponsored:             sponsored,
        note: "#{quantity}x #{product.name}#{is_mixed_crate ? " (Mischkasten)" : ""}#{sponsored ? " (gesponsert)" : ""}"
      )
    end

    if is_mixed_crate && einzelpreis_gesamt > CRATE_PRICE_CENTS && !sponsored
      rabatt = einzelpreis_gesamt - CRATE_PRICE_CENTS
      Transaction.create!(
        purchaser:    @purchaser,
        amount_cents: rabatt,
        kind:         :expense_reimbursement,
        note:         "Kastenrabatt (#{total_quantity} Flaschen)"
      )
    end

    session[:cart] = {}
    redirect_to kiosk_root_path,
      notice: "Einkauf abgeschlossen – #{format("%.2f", total / 100.0)} € gebucht!"
  end

  def clear_cart
    session[:cart] = {}
    redirect_to kiosk_root_path(pin: params[:pin])
  end
end
