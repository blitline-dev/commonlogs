$(function() {
	var atBottom = false;
	var debounce = false;
	var isTailing = true;
	var autoScroll = true;
	var logConsole = new LogConsole();
	var _scrollTimeout;
	var _pauseSmoothScroll = false;
	var _firstLoad = true;
	var _DELAY = 5000;

	$(logConsole).on("afterAppend", function() {
		if (!_pauseSmoothScroll) {
			$("body").stop();
			if (_firstLoad) {
				_firstLoad = false;
				$("body").animate({ scrollTop: $("#console").height() }, 500);
			}else {
				$("body").animate({ scrollTop: $("#console").height() }, _DELAY + 1000);
			}
		}
	});

	function checkTail() {
		if (!isTailing) {
			return;
		}

		var $lastLine = $("#console li:last-of-type");
		var dataT = $lastLine.attr("data-t");
		var dataR = $lastLine.attr("data-r");

		var url = "/features/tail?&name=" + rocketLog.name;

		if (dataT && dataR) {
			url += "&last_prefix=" + dataT + " " + dataR;
		}

		$.get(url, function( data ) {
			logConsole.addRows(data, null, true);
		});
	}

	function checkCookie() {
		if (Utils.getCookie("is_tailing")) {
			if (Utils.getCookie("is_tailing").toString() == "false") {
				isTailing = false;
				$('#tail-checkbox').prop('checked', false);
			}
		}
	}

	function initialize() {
		$("body").scrollTop($("body").height() + 100);

		setInterval(function(){ checkTail(); }, _DELAY);


		$('#tail-checkbox').change(function() {
			isTailing = this.checked;
			document.cookie = "is_tailing=" + isTailing.toString() + "; expires=0; path=/";
		});

		checkTail();
		checkCookie();

		$('html, body').bind('scroll mousedown wheel DOMMouseScroll mousewheel keyup', function(evt) {
			_pauseSmoothScroll = true;

			$("body").stop();

			if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
				_pauseSmoothScroll = false;
			}

			if (_scrollTimeout) {
				clearTimeout(_scrollTimeout);
			}
			// detect only user initiated, not by an .animate though
			_scrollTimeout = setTimeout(function() {
				if ($("body").scrollTop() > $("#console").height() - 100 ) {
					_pauseSmoothScroll = false;
				}
			}, 1000);
		
		});
	}

	initialize();

});