module Web::LocationHelper
  def investigator_present?
    current_investigator && 
    current_investigator.location_id == @location.id
  end
end