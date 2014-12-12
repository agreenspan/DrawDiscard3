module ApplicationHelper

  def flash_message(type, message)
    flash[type] ||= []
    flash[type] << message
  end
  def flash_message_now(type, message)
    flash.now[type] ||= []
    flash.now[type] << message
  end

  def field_empty?(field_name, value)
  	if value.blank? || value.nil? || value.empty?
  		flash_message :danger, "#{field_name} cannot be blank."
  		return true
  	else
  		return false
  	end
  end

end
