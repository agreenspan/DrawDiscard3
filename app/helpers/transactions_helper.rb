module TransactionsHelper

  def price_valid?
    if params[:price].empty?
      flash_message :danger, "Price cannot be blank."
      return false
    elsif params[:price].to_f != params[:price]
      flash_message :danger, "Price must be a number."
      return false
    elsif params[:price] < .01
      flash_message :danger, "Price cannot be less than 0.01 tickets."
      return false
    elsif params[:price] > 999.9
      flash_message :danger, "Price cannot be greater than 999.9 tickets."
      return false
    else 
      return true
    end
  end

  def quantity_valid?
    if params[:quantity].empty?
      flash_message :danger, "Quantity cannot be blank."
      return false
    elsif params[:quantity].to_i != params[:quantity]
      flash_message :danger, "Quantity must be an integer."
      return false
    elsif params[:quantity] < 1
      flash_message :danger, "Quantity cannot be less than 1."
      return false
    elsif params[:quantity] > 999
      flash_message :danger, "Quantity cannot be greater than 999."
      return false
    else 
      return true
    end
  end

end
