$(function() {
	var _logConsole = new LogConsole();
	var _p = 0;
	
	$("body").scrollTop($("body").height() + 100);
	$('#myPleaseWait').modal('show');
	$('.search-results').show();

	$("#customGo").on("event:customTimeSet", function(e) {
  	handleCustomTimeRange();		
	});

	function handleCustomTimeRange() {
		var hours = $("#hours").val();
		var st = hours.split("-")[0];
		var et = hours.split("-")[1];
		window.location.assign("/features/search?&name=" + encodeURIComponent(commonLog.name) + "&st=" + st + "&et=" + et + "&q=" + commonLog.q);	
	}

	function search() {
		_logConsole.setLoading(true);

		var time;
		if (hours) {
			time = "&hours=" + commonLog.hours.toString();
		}else if(st) {
			time = "&st=" + commonLog.st.toString();
			if (et) {
				time += "&et=" + commonLog.et.toString();
			}
		}
		var base64 = window.btoa(commonLog.q);
		var url = "/features/search?&name=" + encodeURIComponent(commonLog.name) + "&q=" + base64 + time + "&p=" + _p.toString();

		$.get(url, function( data ) {
			$('#myPleaseWait').modal('hide');
			var parsedData = JSON.parse(data);
			if (parsedData["count"]) {
				console.log("count", parsedData["count"]);
				var count = 0;
				if ($(".count").text().length > 0) {
					count = parseInt($(".count").text(), 10);
				}
				count += parseInt(parsedData["count"].toString(), 10);
				if (count.toString() != "NaN") {
					$(".count").text("Count: " + count.toString());
				}
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
			}else {
				_p += 1;
				search();				
			}
		});
	}

	function eventChanged($el) {
		var name = $el.attr("data-group");
		var url = "li_home?name=" + name + "&hours=" + commonLog.hours.toString() + "&q=" + encodeURIComponent(commonLog.q);
		window.location = url;
	}

	$(".group").click(function() {
		eventChanged($(this));
		return false;
	});

	search();

});