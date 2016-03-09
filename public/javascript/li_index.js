$(function() {
	var isTailable = false;
	var atBottom = false;
	var debounce = false;
	var isTailing = true;
	var autoScroll = true;
	var logConsole = new LogConsole();

	$(logConsole).on("afterAppend", function() {
		// Scroll if necessary
		if (isTailable && autoScroll) {
			autoscroll();
		}
	});

	function setBottom() {
		if (debounce) { return; }
		if($(window).scrollTop() + $(window).height() == $(document).height()) {
			atBottom = true;
		}else {
			atBottom = false;
		}
	}

	function autoscroll() {
		debounce = true;
		$('html, body').animate({
			scrollTop: $("#console").height()
		},	'slow');
		debounce = false;
	}

	function checkTail() {
		if (!isTailing) {
			return;
		}
		var $lastLine = $("#console li:last-of-type");
		var lastLinePrefix = $lastLine.attr("data-rsyspref");

		var url = "tail?&name=" + rocketLog.name + "&last_prefix=" + lastLinePrefix.replace("+", "%2b");

		$.get(url, function( data ) {
			logConsole.addRows(data);
		});
	}

	$("body").scrollTop($("body").height() + 100);

	if (isTailable) {
		setInterval(function(){ checkTail(); }, 5000);

		$('input[name="my-checkbox"]').on('switchChange.bootstrapSwitch', function(event, state) {
			isTailing = state;
		});
	}else {
		isTailing = false;
	}

	$(window).scroll(function() {
		setBottom();
	});

});