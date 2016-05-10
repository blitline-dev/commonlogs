$(function() {
	var _logConsole = new LogConsole();
	var _p = 0;
	
	$("body").scrollTop($("body").height() + 100);
	$('#myPleaseWait').modal('show');


	function search() {
		_logConsole.setLoading(true);
		var url = "/features/search?&name=" + commonLog.name + "&q=" + commonLog.q + "&hours=" + commonLog.hours + "&p=" + _p.toString();

		$.get(url, function( data ) {
			$('#myPleaseWait').modal('hide');
			var parsedData = JSON.parse(data);
			if (parsedData["count"]) {
				console.log("count", parsedData["count"]);
				var count = 0;
				if ($(".count").text().length > 0) {
					count = parseInt($(".count").text(), 10);
				}
				console.log("count2", count);
				count += parsedData["count"];
				console.log("count3", count);
				console.log("count4", count.toString());
				$(".count").text("Count: " + count.toString());
			}
			_p = parsedData["page"];

			if(parsedData["data"] && parsedData["data"].length > 0) {
				_logConsole.addRows(parsedData["data"], "search");
			}else {
				_logConsole.setEmpty();
			}
			_logConsole.setLoading(false);

			if (!parsedData["has_more"]) {
				_logConsole.clearLoading();
			}
		});
	}

	$(_logConsole).on("loadMore", function() {
		search();
	});

	function eventChanged($el) {
		var name = $el.attr("data-group");
		var url = "li_home?name=" + name + "&hours=" + commonLog.hours.toString() + "&q=" + commonLog.q;
		window.location = url;
	}

	$(".group").click(function() {
		eventChanged($(this));
		return false;
	});

	search();

});