jQuery(function ($) {
  var assignedAllyIds = [];
  var assignedContactIds = [];

  function hasAssignedContactId(id) {
	return assignedContactIds[id] == true;
  }
  function assignContact(id) {
	assignedContactIds[id] = true;
  }
  function unassignContact(id) {
	assignedContactIds[id] = false;
  }

  function hasAssignedAllyId(id) {
	return assignedAllyIds[id] == true;
  }
  function assignAlly(id) {	
	
	logx( 'assinging to array ' + id );
	assignedAllyIds[id] = true;
  }
  function unassignAlly(id) {	
	logx( 'removing from array ' + id );
	assignedAllyIds[id] = false;
  }

  function logx(msg) {
    var console = window['console'];
    if (console && console.log) {
      console.log(msg);
    }	
  }

  $('.assigner').live('click', function (e) {
    var assigner = $(this);
    var lister = assigner.children('ul').first();

    if (lister.hasClass('hidden')) {
	  lister.removeClass('hidden');
	  assigner.removeClass('selected');
	  assigner.addClass('picked');
	
	  var label = assigner.children('span[data-label|=ally]').first();
	  if (label.text() ) {
	    label.text('Assign an ally to help with this intrigue');
	    var input = assigner.children('input[data-field|=ally]');
	    unassignAlly( input.val() );
		logx( 'in array ' + hasAssignedAllyId( input.val() ) );
	    input.val('');
      }

      label = assigner.children('span[data-label|=contact]').first();	
	  if (label.text() ) {
	    label.text('Use a favor to assign a contact to help with this intrigue');
	    var input = assigner.children('input[data-field|=contact]');
	    unassignContact( input.val() );
	    input.val('');
      }	  
    } else {
	  lister.addClass('hidden');
	  assigner.removeClass('picked');
    };
  });

  $('[data-command|=assign-contact]').live('click', function (e) {	
    var commander = $(this);
    var assigner = commander.parents('.assigner').first();

    var id = commander.attr('data-id');
	if (hasAssignedContactId(id) == true) {
	  alert( 'Contact already investigating another intrigue.' );
	  return false;
	}
	
    assigner.addClass('selected');

    var input = assigner.children('input[data-field|=contact]');
    input.val(id);
    assignContact(id);
    logx('set conatact id ' + id);

    var name = commander.children('span[data-label|=name]').text();
    var challenge = $('span[data-label|=challenge]', commander).text();
    var skill = $('span[data-label|=skill]', commander).text();

    var label = assigner.children('span[data-label|=contact]').first();
	label.text(name + ' | +' + skill + ' ' + challenge + ' bonus');
  });

  $('[data-command|=assign-ally]').live('click', function (e) {	
    var commander = $(this);
    var assigner = commander.parents('.assigner').first();

    var id = commander.attr('data-id');
	if (hasAssignedAllyId(id) == true) {
	  alert( 'Ally already investigating another intrigue.' );
	  return false;
	}
	
    assigner.addClass('selected');

    var input = assigner.children('input[data-field|=ally]');
    input.val(id);
    assignAlly(id);
    logx('set ally id ' + id);
	
    var name = commander.children('span[data-label|=name]').text();
    var challenge = $('span[data-label|=challenge]', commander).text();
    var skill = $('span[data-label|=skill]', commander).text();

    var label = assigner.children('span[data-label|=ally]').first();
	label.text(name + ' | +' + skill + ' ' + challenge + ' bonus');
  });

  $('.submit.solution').live('click', function (e) {	
    var el = $(this);
    var hidden = $('#plot_thread_solution_id');
	var solution_id = el.attr('data-solution-id');
	hidden.val(solution_id);
  });
});	