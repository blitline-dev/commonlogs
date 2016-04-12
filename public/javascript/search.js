$(function() {
	var _logConsole = new LogConsole();
	var _p = 0;
	
	$("body").scrollTop($("body").height() + 100);
	$('#myPleaseWait').modal('show');


	function search() {
		_logConsole.setLoading(true);
		var url = "/features/search?&name=" + rocketLog.name + "&q=" + rocketLog.q + "&hours=" + rocketLog.hours + "&p=" + _p.toString();

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
				$(".count").text(count.toString());
			}
			_p = parsedData["page"];
			_logConsole.addRows(parsedData["data"], "search");
			_logConsole.setLoading(false);
			$(".count").text();
			if (!parsedData["has_more"]) {
				_logConsole.clearLoading();
			}
		});
	}

	$(_logConsole).on("loadMore", function() {
		search();
	});

	search();

});