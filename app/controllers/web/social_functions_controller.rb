class Web::SocialFunctionsController < Web::WebController
  def index
    @social_functions = SocialFunction.all
    
    if current_investigator
      @social = current_investigator.socials.active.first
      @socials = Social.active.for_allies current_investigator.inner_circle.map(&:id)
    end
  end
end