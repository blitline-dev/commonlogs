$(function() {
	var _logConsole = new LogConsole();

	$('#myPleaseWait').modal('show');

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
		var $item = $("li[data-t='" + rocketLog.time.toString() + "'][data-r='" + rocketLog.seq+ "']");
		$item.attr("style", "background-color: #fff06e; color: #000;");
		scrollToCenter($item);
	}

	function loadContextData() {
		_logConsole.setLoading(true);
		var url = "context_data?&name=" + rocketLog.name + "&seq=" + rocketLog.seq + "&server=" + rocketLog.server + "&file=" +rocketLog.file + "&time=" + rocketLog.time.toString();

		$.get(url, function( data ) {
			$('#myPleaseWait').modal('hide');
			_logConsole.addRows(data, null);
			_logConsole.setLoading(false);
			highlight();
		});
	}

	loadContextData();
	
});




