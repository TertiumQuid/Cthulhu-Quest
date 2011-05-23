jQuery(function ($) {
  $('li.radio input:radio').live('click', function (e) {
    var el = $(this);
    parent = el.parents('li.radio');
	parent.addClass('selected');
	
    var radios = parent.siblings('.selected');
    radios.each(function(index) {
	  $(this).removeClass('selected'); 
	});
  });
});	