$(function(){
	var _colorPicker = null;

	_colorPicker = $('.demo2').colorpicker({
		format: "hex",
		align: "left",
		color: '#'+Math.floor(Math.random()*16777215).toString(16)
	});

	$(".notify").click(function() {
		window.location = $(this).attr("data-nav");
	});

	$(".add_event").click(function() {
		setTimeout(function() {
			if ($("#cp").val() == "") {
				_colorPicker.colorpicker('setValue', '#'+Math.floor(Math.random()*16777215).toString(16));
			}
		}, 0);
	});

	$('#myModal').on('hidden.bs.modal', function () {
    	$("#eventName").val("");
    	$("#cp").val("");
    	$("#description").val("");
    	$("#searchWord").val("");
	})

  $('#myModal').on('shown.bs.modal', function () {
    $('#myModal form').validator('destroy')
    var validator = $('#myModal form').validator();
      validator.on('submit', function (e) {
        if (e.isDefaultPrevented()) {
          // handle the invalid form...
          alert("Please correct the form errors before continuing");
          return false;
        }
      });
  })

  // ------- Log Group Switch
  $(".group").click(function() {
    eventChanged($(this));
    return false;
  });

  function eventChanged($el) {
    var name = $el.attr("data-group");
    var url = "event_manager?name=" + name;
    window.location = url;
  }
  // ------- End Group Switch

	$(document).ready(function(){
    $('[data-toggle="tooltip"]').tooltip(); 
	});

	$(".evedit").click(function() {
		var eventName = $(this).attr("data-event-id");
    $.ajax({
      method: "GET",
      url: "/events?name=" + commonLog.name + "&event=" + eventName,
      success: function(data) {
      	$("#eventName").val(data.event_name);
      	$("#cp").val(data.color);
      	$("#description").val(data.description);
      	$("#searchWord").val(data.search || data.find);
      	_colorPicker.colorpicker('setValue', data.color);
      	$(".add").click();
      },
      error: function (xhr, exception, error) {
        console.dir[xhr, exception, error]
        swal('Nope', 'Failed to get data from server', 'error');
      },
      dataType: "json"
    });		
	})
    
});
