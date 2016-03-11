$(function() {
	var _logConsole = new LogConsole();
	var _p = 0;

	$("body").scrollTop($("body").height() + 100);
	$('#myPleaseWait').modal('show');


	function search() {
		_logConsole.setLoading(true);
		var url = "/search?&name=" + rocketLog.name + "&q=" + rocketLog.q + "&hours=" + rocketLog.hours + "&p=" + _p.toString();

		$.get(url, function( data ) {
			$('#myPleaseWait').modal('hide');
			var parsedData = JSON.parse(data);
			_p = parsedData["page"];
			_logConsole.addRows(parsedData["data"], "search");
			_logConsole.setLoading(false);
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