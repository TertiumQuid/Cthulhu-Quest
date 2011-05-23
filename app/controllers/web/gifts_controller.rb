class Web::GiftsController < Web::WebController
  before_filter :require_user
  before_filter :require_investigator
  
  def create
    @gift = current_investigator.giftings.new( params[:gift] )
    @gift.investigator = @investigator = Investigator.find( params[:investigator_id] )
    
    if @gift.save
      flash[:notice] = if @gift.funds?
        "You sent your ally a gift of #{@gift.gift_name}, and they shall be pleased to receive it."
      elsif @gift.item?
        "You sent your ally your #{@gift.gift_name} as a gift. They shall be pleased to receive it."
      end
    else
      flash[:error] = @gift.errors.full_messages.join(", ")
    end
    redirect_to web_investigator_path( @investigator )
  end
end