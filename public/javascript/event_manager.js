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
      url: "/events?name=" + rocketLog.name + "&event=" + eventName,
      success: function(data) {
      	$("#eventName").val(data.event_name);
      	$("#cp").val(data.color);
      	$("#description").val(data.description);
      	$("#searchWord").val(data.search);
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
