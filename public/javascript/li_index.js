$(function() {

	var atBottom = false;
	var debounce = false;
	var isTailable = rocketLog.q.length == 0;
	var isTailing = true;

	function setBottom() {
		if (debounce) { return; }
		if($(window).scrollTop() + $(window).height() == $(document).height()) {
			atBottom = true;
		}else {
			atBottom = false;
		}
	}

	function cleanup() {
		var numItems = $('.r').length;
		if (numItems > 10000) {
			$("#console").find(".r:lt(" + allHtml.length + ")").remove();
		}
	}

	function autoscroll() {
		debounce = true;
		$('html, body').animate({
			scrollTop: $("#console").height()
		},	'slow');
		debounce = false;
	}

	function addRows(data) {
		var row;
		var rowDate;
		var href;
		var html;
		var allHtml = [];

		for(var i = 0; i < data.length; i++) {
			row = data[i];
			rowDate = row[0].substring(5,19).replace("T","-");

			href = "/context?name=" + rocketLog.name + "&time=" + row[0] + "&server=" + row[2] + "&seq=" + row[1] + "&file=" + row[4];
			html = [
				"<li class='r' data-rsyspref='" + row[0] + " " + row[1] + " " + row[2] + "'>",
				"<span class='muted'>" + rowDate + "&nbsp;</span>",
				"<a class='niceLink' href='" + href + "'>" + row[2] + "</a>",
				"<span>&nbsp;" + row[3] + "</span>",
			];

			allHtml.push(html.join(""));
		}

		var autoScroll = atBottom;
		$newNode = $(allHtml.join(""));
		$("#console").append($newNode);
		cleanup();

		console.dir(data);
		if (autoScroll) {
			autoscroll();
		}
	}

	function checkTail() {
		if (!isTailing) {
			return;
		}
		var $lastLine = $("#console li:last-of-type");
		var lastLinePrefix = $lastLine.attr("data-rsyspref");

		var url = "tail?&name=" + rocketLog.name + "&last_prefix=" + lastLinePrefix.replace("+", "%2b");

		$.get(url, function( data ) {
			addRows(data);
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