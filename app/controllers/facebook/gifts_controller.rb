class Facebook::GiftsController < Facebook::FacebookController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @gift = current_investigator.giftings.new( params[:gift] )
    @gift.investigator = @investigator = Investigator.find( params[:investigator_id] )
    
    if @gift.save
      render_and_respond :success, :message => success_message, :title => 'Gift sent to ally', :to => return_path
    else
      render_and_respond :failure, :message => failure_message, :title => 'Could not send gift', :to => return_path
    end
  end
  
private

  def return_path
    facebook_investigator_path(@investigator)
  end

  def failure_message
    @gift.errors.full_messages.join(", ")
  end

  def success_message
    if @gift.funds?
      "You sent your ally a gift of #{@gift.gift_name}, and they shall be pleased to receive it."
    elsif @gift.item? || @gift.weapon?
      "You sent your ally your #{@gift.gift_name} as a gift. They shall be pleased to receive it."
    end    
  end  
end