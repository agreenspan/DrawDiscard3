class TransactionsController < ApplicationController
  def transaction
    if !@user.present?
      flash_message :danger, "You must be logged in to buy or sell cards."
      redirect_to :back and return
    end
    errors = false
    errors = true unless price_valid?
    errors = true unless quantity_valid?
    errors = true unless object_valid?
    redirect_to :back and return if errors == true
    @time = DateTime.now
    case params[:commit]
      when "Buy"
        errors = true unless enough_tickets?
        redirect_to :back and return if errors == true
        buy
      when "Sell"
        errors = true unless enough_cards?
        redirect_to :back and return if errors == true
        sell
    end
    redirect_to :back and return
  end

  def cancel
    redirect_to :back and return
  end
end
