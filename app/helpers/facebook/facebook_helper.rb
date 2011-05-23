module Facebook::FacebookHelper
  def navigation_button(index,text,path,opts={})
    render :partial => 'facebook/facebook/navigation_button', 
           :locals => { :button_index => index, :button_text => text, :button_path => path, :button_opts => opts }
  end
  
  def investigator_activity_item(text,desc,path,time_in_percent,time_text)
    render :partial => 'facebook/facebook/activity_item', 
           :locals => { :link_text => text, :link_desc => desc, :link_path => path, 
                        :time_text => time_text, :time_in_percent => time_in_percent }
  end
  
  def investigator_news_item(item)
    render :partial => 'facebook/facebook/newswire_item', 
           :locals => { :investigator_name => item.investigator.name, :message => item.message, 
                        :investigator_image => "/images/web/background.jpg", :time_text => time_ago_in_words(item.created_at) }    
  end
  
  def grid_table(array, options = {}, &proc)
    if array.blank?
      concat("")
      return
    end
    rows = options[:rows] || 2
    cols = options[:cols] || 4
    size = array.size
		cell_leftover = (size % size - 1)
    cell_count = (size + (cell_leftover > 0 ? (cols - cell_leftover) : 0))
        
	  output = raw("<table><tbody>") +
		raw("<tr>") +
	  raw("<td class='left-nav pager' data-index='-#{rows}'><a href='#'></a></td>") +
    raw("<td>") +
    raw("<table class='grid' data-index='0'>")
    concat(output)
    
    cell_count.times do |idx|
      data_idx = idx / cols
      hidden = idx >= (rows * cols) - 1 ? 'hidden' : ''
		  concat("<tr class='#{hidden}' data-index='#{data_idx}'") if (idx % cols == 0)
      
      item = idx < size ? array[idx] : nil
      proc.call(item, idx)
      
			concat("</tr>") if (idx % 4 == 3)
    end
    
    
		output = raw("</td>") +
    raw("<td class='right-nav pager' data-index='2'><a></a></td></tr>") +
    raw("</table>") +
    raw("</tbody></table>")
    concat(output)
  end
end