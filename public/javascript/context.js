$(function() {
	var _logConsole = new LogConsole();

	$('#myPleaseWait').modal('show');

	function eventChanged($el) {
		var name = $el.attr("data-group");
		var url = "li_home?name=" + name + "&hours=" + commonLog.hours.toString();
		window.location = url;
	}

	$(".group").click(function() {
		eventChanged($(this));
		return false;
	});

	function scrollToCenter(el) {
		var elOffset = el.offset().top;
		var elHeight = el.height();
		var windowHeight = $(window).height();
		var offset;

		if (elHeight < windowHeight) {
			offset = elOffset - ((windowHeight / 2) - (elHeight / 2));
		}
		else {
			offset = elOffset;
		}
		var speed = 100;
		$('html, body').animate({scrollTop:offset}, speed);
	}

	function highlight() {
		var $item = $("li[data-t='" + commonLog.time.toString() + "'][data-r='" + commonLog.seq+ "']");
		$item.attr("style", "background-color: #fff06e; color: #000;");
		scrollToCenter($item);
	}

	function loadContextData() {
		_logConsole.setLoading(true);
		var url = "/features/context_data?&name=" + commonLog.name + "&seq=" + commonLog.seq + "&server=" + commonLog.server + "&file=" +commonLog.file + "&time=" + commonLog.time.toString();

		$.get(url, function( data ) {
			$('#myPleaseWait').modal('hide');
			_logConsole.addRows(data, null);
			_logConsole.setLoading(false);
			highlight();
		});
	}

	loadContextData();
	
});




