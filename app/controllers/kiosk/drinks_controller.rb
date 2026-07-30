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
      @full_crates = @total_quantity / CRATE_SIZE
      @single_products = @total_quantity % CRATE_SIZE
      @is_mixed_crate = @total_quantity == CRATE_SIZE
      @cart_total = calculate_total(@cart, current_organization)
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
    full_crate = total_quantity / CRATE_SIZE
    single_product = total_quantity % CRATE_SIZE

    total = calculate_total(cart, current_organization)

    # Saldo-Check gilt nur für Members, nicht für Gäste (Gäste bekommen Rechnung)
    if @purchaser.is_a?(Member) && !@purchaser.can_purchase?(sponsored ? 0 : total)
      redirect_to kiosk_root_path(pin: params[:pin]),
        alert: "Saldo zu niedrig (Limit: -50€)" and return
    end

    cart.each do |product_id, quantity|
      product = current_organization.products.find(product_id)
      full_crate_for_product = quantity / CRATE_SIZE
      single_product_for_product = quantity % CRATE_SIZE
      full_amount = product.price_cents * quantity

      if is_mixed_crate && !sponsored
        reduced_per_bottle = CRATE_PRICE_CENTS / CRATE_SIZE
        actual_amount = reduced_per_bottle * quantity
      else
        actual_amount = full_amount
      end

      if full_crate_for_product > 0
        part = full_crate_for_product * CRATE_PRICE_CENTS
        Transaction.create!(
          purchaser:             @purchaser,
          product:               product,
          amount_cents:          sponsored ? 0 : -part,
          original_amount_cents: product.price_cents * quantity,
          kind:                  :drink_purchase,
          quantity:              full_crate_for_product * CRATE_SIZE,
          sponsored:             sponsored,
          note: "#{full_crate_for_product * CRATE_SIZE}x #{product.name} (#{full_crate_for_product} Kasten)"
        )
      end

      if single_product_for_product > 0
        part = single_product_for_product * product.price_cents
        Transaction.create!(
          purchaser:             @purchaser,
          product:               product,
          amount_cents:          sponsored ? 0 : -part,
          original_amount_cents: part,
          kind:                  :drink_purchase,
          quantity:              single_product_for_product,
          sponsored:             sponsored,
          note: "#{single_product_for_product}x #{product.name}"
        )
      end
    end

    session[:cart] = {}
    redirect_to kiosk_root_path,
      notice: "Einkauf abgeschlossen – #{format("%.2f", total / 100.0)} € gebucht!"
  end

  def clear_cart
    session[:cart] = {}
    redirect_to kiosk_root_path(pin: params[:pin])
  end

  private

  def calculate_total(cart, organization)
    cart.sum do |product_id, quantity|
      product = organization.products.find(product_id)
      full_crate = quantity / CRATE_SIZE
      single_product = quantity % CRATE_SIZE
      (full_crate * CRATE_PRICE_CENTS) + (single_product * product.price_cents)
    end
  end
end
