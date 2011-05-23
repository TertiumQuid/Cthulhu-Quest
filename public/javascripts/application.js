(function( $ ){
  $.fn.bindAjaxRequester = function(options) {
	options = options || {};
	var trigger = $(this);
	if ( options.button != false ) { 
		if (options.button) {
		  options.button.button(); 
		} else {
          trigger.button(); 			
		};
	};
	
	var dialogOptions = { 
	  autoOpen: true, 
      show: {effect: "fade", duration: 300},		
      hide: {effect: "fade", duration: 200},
      position: ['center','top'],
	  modal: true,
	  closeOnEscape: false,
	  resizable: false,
	  minHeight: options.height || 250,
	  width: 700,
	  buttons: options.buttons || { "Very Well": function(){ $(this).dialog( "close" ); }}
	};
	var dialog;
	
	/* add a confirmation dialog to the event, allowing the request to send only if a data attr flag is set */
	if ( options.confirmation ) {
	  trigger.bind( 'click', function(event){	
	    var retrigger = $(this);
	    if ( retrigger.attr('data-confirmed') == 'true') { return true; };
	    event.preventDefault();
	
	    dialogOptions.title = "Are You Certain?";
	    dialogOptions.buttons = {
		  "Nevermind": function() { $(this).dialog( "close" ); },
		  "Continue": function() { 
		    retrigger.attr('data-confirmed', true);
		    retrigger.trigger('click');
	        $(this).dialog( "close" ); 
	      }		
	    };
	
	    $("<div />", { html: '<p>'+options.confirmation+'</p>' }).dialog(dialogOptions);   
	    return false; 
	  });	
	};

    $(this).bind("ajax:beforeSend", function(obj, data, status, xhr) {	
	  if ( options.button ) { trigger.button('disable'); };
    });
	
    $(this).bind("ajax:success", function(obj, data, status, xhr) {	
      var json = jQuery.parseJSON(data);
      var sender = $(this);

      /* session timeout */
      if ( json.status == 'session') { 
        dialog = $("<div />", { html: '<p><br />' + json.message + '</p>' })
      /* post/put/delete request, show results */
	  } else if ( sender.attr('data-method') || trigger.is("form") ) {  
		if (json.html) { /* option to treat response as a get request and show page */
	      dialog = options.dialogContainer || $("#dialogs").empty();
	      dialog.html(json.html);
		} else {
		  dialog = $("<div />", { html: json.html || ('<p><br />' + json.message + '</p>') })	
		};
	    dialogOptions.buttons = {
		  "Very Well": function() {
			if ( json.status == 'success' && options.success ) { 
			  options.success(sender, json.html, json.json); 
			} else if ( json.status == 'failure' && options.failure ) { 
			  options.failure(sender); 
			} else if ( json.status == 'redirect') {
			  top.location = json.to;
			};
			$(this).dialog( "close" );
		  }		
	    };
	  /* get request, show page */
	  } else { 
	    dialog = options.dialogContainer || $("#dialogs").empty();
	    dialog.html(json.html);		
	  };

      dialogOptions.title = json.title;	
	  dialog.dialog(dialogOptions);
    });

    $(this).bind("ajax:error", function(obj, data, status, xhr) {
	  dialogOptions.title = "Arcane Server Error";
	  var errorText = "Something terrible has happened on the server, causing an error in time and space. The appropriate deities have been notifed and will soon ply their magic to resolve the issue.";
	  $("<div />", { html: '<p><br />'+errorText+'</p>' }).dialog(dialogOptions);
    });

    $(this).bind("ajax:complete", function(obj, data, status, xhr) {	
	  if ( options.button ) { trigger.button('enable'); };
	  if ( options.confirmation ) { trigger.attr('data-confirmed', false); };
    });
  };

})( jQuery );


(function( $ ){
  $.fn.paginated = function(opts) {		
	if (!opts) opts = {};
	
	var ul = $(this);
	var li = ul.children('li');

    var ctrls = opts.controls;
    if (ctrls) {
	  var prev = ctrls.prev;
	  var next = ctrls.next;
	  prev.addClass('disabled');
    };

	var itemsPerPage = opts.perPage || 3;
	var pageCount = Math.ceil( li.length / itemsPerPage );
	
	function disableNav() {
	  if (prev && next) {
		prev.addClass('disabled');
		next.addClass('disabled');
	  };		
	};
	function enableNav() {
	  if (prev && next) {
		prev.removeClass('disabled');
		next.removeClass('disabled');
	  };		
	};
	if (pageCount<2) {
	  disableNav();
	  return this;
	}
	
	for(var i=0;i<pageCount;i++) {
      li.slice(i*itemsPerPage,(i+1)*itemsPerPage).wrapAll('<div class="paginated-page" style="" />');
	};
	
	var pages = ul.children('.paginated-page');
	pages.hide().first().show();
	
	var currentPage = 0;
	ul.attr('data-page', currentPage);
    if (ctrls) {
	  prev.click(function(e){
		if (prev.hasClass('disabled')) return;
		var pg = parseInt(ul.attr('data-page'));
		if (pg-1< 0) return false;
		
		disableNav();
		pages.eq(pg).fadeOut(200, "linear", function(){
		  pages.eq(pg-1).fadeIn(200, "linear", function(){
			enableNav();
		  });
		});				
		
		ul.attr('data-page', pg-1);
	  });
	
	  next.click(function(e){
		if (next.hasClass('disabled')) return;
		var pg = parseInt(ul.attr('data-page'));
		if (pg+1>=pages.length) return false;
		
		disableNav();
		pages.eq(pg).fadeOut(200, "linear", function(){
		  pages.eq(pg+1).fadeIn(200, "linear", function(){
			enableNav();
		  });
		});
		
		ul.attr('data-page', pg + 1);
	  });	
	};
		
	return this;
  };
})( jQuery );

function setFundsLabel(modifier) {
  var lbl = $(".investigator-funds");
  var val = lbl.text();
  var newValue = parseInt(val) + parseInt(modifier);
  lbl.text( newValue );
};

function setWoundsLabel(status, label) {
  var lbl = label || $(".investigator-wounds");
  lbl.text(status);
};

function setMadnessLabel(status, label) {
  var lbl = label || $(".investigator-madness");
  lbl.text(status);
};

function animateProgressBar(target, start, stop, steps){
  var step = (stop - start)/steps;
  var increment = function() {
    var val = target.progressbar("value");
    target.progressbar("option", "value", val + step);
    if (val + step < stop) { setTimeout(increment, 10); };
  };
  increment();
};

function removeStatusItem(kind) {
  var el = $("#activity-"+kind);
  el.fadeOut(600, function() { el.remove(); });
};

function addStatusItem(title, kind, duration) {
  var ul = $('#investigator-activity-list');

  var lbl = '';
  if (kind == 'investigating') {
    lbl = 'Investigating';
  } else if (kind == 'hosting') {
 	lbl = 'Hosting';
  } else if (kind == 'casting') {
    lbl = 'Casting';
  } else if (kind == 'treating') {
	lbl = 'Treating Your';
  };

  var li = $('<li id="activity-'+kind+'"></li>');
  var p = $('<p><strong id="progress-link-'+kind+'">'+lbl+'</strong> '+title+'</p>')
  var bar = $('<div id="progress-activity-bar-'+kind+'" class="activity-progress progressbar">');
  var time = $('<span>'+(duration || '')+'</span></div>');

  p.appendTo(li);
  bar.appendTo(li);
  time.appendTo(li)
  bar.progressbar({ value: 0 });
  
  $('#activity-inactive').remove();

  li.appendTo(ul)
  li.hide().fadeIn(700);
};