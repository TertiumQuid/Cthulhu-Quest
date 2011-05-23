namespace :test do
  def lf(level)
    (( (level+1) - 1) ** 2 ) + 10
  end
  
  desc "Print Out Formula Results"
  task(:formula => :environment) do
    51.times do |level| 
      next if level< 2
      
      req = lf(level)
      last_req = level==1 ? 0 : lf(level-1)
      diff = (req - last_req).to_i
      puts "Level #{level} needs #{req.to_i} (diff of #{diff})"
    end
  end
end