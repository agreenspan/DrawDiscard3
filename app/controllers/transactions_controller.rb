class TransactionsController < ApplicationController
  def transaction
    if !@user.present?
      flash_message :danger, "You must be logged in to buy or sell cards."
      redirect_to :back and return
    end
    errors = false
    errors = true unless price_valid?
    errors = true unless quantity_valid?
    redirect_to :back and return if errors == true


    case params[:commit]
      when "Buy"
    
      when "Sell"

    end  

    redirect_to :back and return
  end

  def cancel
    redirect_to :back and return
  end
end
