$(function() {
	var atBottom = false;
	var debounce = false;
	var isTailing = true;
	var autoScroll = true;
	var logConsole = new LogConsole();

	$(".tailer").show();

	$(logConsole).on("afterAppend", function() {
		console.log("afterAppend");
		// Scroll if necessary
		if (autoScroll) {
			autoscroll();
		}
	});

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

		var url = "tail?&name=" + rocketLog.name;

		if (lastLinePrefix && lastLinePrefix.length > 0) {
			url += "&last_prefix=" + lastLinePrefix.replace("+", "%2b");
		}

		$.get(url, function( data ) {
			logConsole.addRows(data);
		});
	}

	$("body").scrollTop($("body").height() + 100);

	setInterval(function(){ checkTail(); }, 1000000);

	$('input[name="my-checkbox"]').on('switchChange.bootstrapSwitch', function(event, state) {
		isTailing = state;
	});

	$(window).scroll(function() {
//		setBottom();
	});

	checkTail();

});