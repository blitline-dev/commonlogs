$(function()	{
	$(".searchBox").hide();

	var	_VIEWSIZE = 180;
	var _chartData = { "columns" : [], "maxY" : 0};
	var _logConsole = new LogConsole();
	var _startTime;
	var _slice;
	var _eventName;
	var _page = 0;
	var _customRange = null;
	
	function resetPointer() {
		$("#pointer").hide();
		$("#pointer").css({ left: -100});
	}

	function massageData(data) {
		//	Assume	data	in	format	
		//	{ "xxx" : counts...}
		var keys = Utils.getKeys(data);
		var maxAll = 0;
		for (var k=0; k<keys.length; k++) {
			var sum = Utils.sumValues(data[keys[k]]);
			var max = Utils.maxValue(data[keys[k]]);
			if (max > maxAll) {
				maxAll = max;
			}
			if (sum > 0) {
				// Insert name into first entry
				var rowData = [keys[k] + " (" + sum.toString() + ")"];
				// Concat count data into array
				rowData = rowData.concat(data[keys[k]]);
				_chartData["columns"].push(rowData);
			}
		}
		_chartData.maxY = maxAll;
	}

	function timeSliceAsTime(timeSliceIndex) {
		var dateTime = _startTime + (timeSliceIndex * _slice);
		return new Date(dateTime * 1000);
	}

	function timeAsTimeSlice(time) {
		var sliceIndex = ((time.getTime() / 1000) - _startTime) / _slice;

		return sliceIndex;
	}

	function indexClicked(index, id) {
		
		var startTime = _startTime + (index * _slice);
		var endTime = _startTime + (index * _slice) + _slice;
		
		_customRange = [startTime, endTime];

		$('#myPleaseWait').modal('show');
		_logConsole.clear();
		_page = 0;
		_eventName = id.split(" ")[0];
		getEventsList(_eventName);
	}

	function drawChart() {
		var data	=	{
			selection: {
				enabled: true,
				multiple: false
			},
			onclick: function(e) {
				var index = e.index;
				var id = e.id;
				indexClicked(index, id);
			},
			onselected: function(e) {
			},
			type: 'scatter'
		};

		data["columns"] = _chartData.columns;
		data["colors"] = {};
		data["colors"][_chartData["columns"][0][0]] = '#ff0000';

		_chartData.maxY = _chartData.maxY * 1.20;
		var chartMax  = Math.ceil(_chartData.maxY / (Math.pow(10, Math.floor(Math.log10(_chartData.maxY))) / 10)) * (Math.pow(10, Math.floor(Math.log10(_chartData.maxY))) / 10);

		var	chart	=	c3.generate({
			bindto:	'#chart',
			point:  {
				r: function (d) {
					if (d.value === null) {
						return 0;
					}
					return 3;
				}
			},
			grid: {
				y: {
						show: true
				},
				x: {
						show: true
				}
			},
			axis: {
				y: {
					min: 0,
					max: chartMax,
					padding: {top:0, bottom:0},
					tick: {
						count: 5,
						fit: true,
						format: function (d) {
							if (d > 0) {
								return Math.round(d).toString();
							}
							return 0;
						}
					}
				},
				x: {
					tick: {
						fit: true,
						format: function (d) {
							return Utils.formatDate(timeSliceAsTime(d), rocketLog.hours);
						}
					}
				}
			},
			legend: {
				item: {
					onclick: legendClick
				}
			},
			onrendered: chartRendered,
			transition:	{
				duration:	200
			},
			data:	data
		});
	}

	function chartRendered() {
		// Chart Rendered Event
	}

	function legendClick(id) {
		$('#myPleaseWait').modal('show');
		_logConsole.clear();
		resetPointer();
		_page = 0;
		_eventName = id.split(" ")[0];
		getEventsList(_eventName);
	}

	function getEventsData(url) {
		$.get(url, function( rawData ) {
			try {
				var data = JSON.parse(rawData);
				if (jQuery.isEmptyObject(data["event_data"]) || data["event_data"] === "{}") {
					showEmptyChart();
					afterRender();
					return;
				}

				start_timestamp = data["st"];
				end_timestamp = data["et"];
				event_data = data["event_data"];
				_startTime = start_timestamp;
				_slice = (end_timestamp - _startTime) / _VIEWSIZE;

				massageData(event_data);
				drawChart();
				afterRender();
			}catch(ex) {
				console.log(ex.stack);
			}
		});
	}

	function getEventsList(eventName) {
		var hours = Utils.getParameterByName("hours");
		var st = Utils.getParameterByName("st");
		var et = Utils.getParameterByName("et");

		var url = "/event_list?name=" + rocketLog.name + "&event_name=" + eventName + "&page=" + _page;


		if (!_customRange) {
			if (hours) {
				url += "&hours=" + hours.toString();
			}else if(st) {
				url += "&st=" + st.toString();
				if (et) {
					url += "&et=" + et.toString();
				}
			}
		}else {
			url += "&st=" + _customRange[0].toString();
			url += "&et=" +  _customRange[1].toString();
		}

		$.get(url, function( data ) {
			try {
				$("#pointer").show();
				_logConsole.addRows(JSON.parse(data), eventName);
				_logConsole.setLoading(false);
				$("#parentChart").addClass("botborder");
				$('#myPleaseWait').modal('hide');
			}catch(ex) {
				console.log(ex.stack);
			}
		});
	}

	function showEmptyChart() {
		var chart = c3.generate({
			bindto:	'#chart',
			data: {
				columns: [
					['data', 0]
				],
				type: 'gauge',
				gauge: {
					label: {
						format: function(value, ratio) {
							return "No data available";
						}
					}
				},
				color: {
					color: "#ff0000"
			}}
		});

		$("#belowChart").show();
	}

	function afterRender() {
		$('#myPleaseWait').modal('hide');
	}

	// Load data after page loads
	setTimeout( function() {
		var hours = Utils.getParameterByName("hours");
		var st = Utils.getParameterByName("st");
		var et = Utils.getParameterByName("et");

		var url = "/event_counts?name=" + rocketLog.name;
		if (hours) {
			url += "&hours=" + hours.toString();
		}else if(st) {
			url += "&st=" + st.toString();
			if (et) {
				url += "&et=" + et.toString();
			}
		}
		getEventsData(url);
	}, 0 );

	$(".hrs").click(function() {
		var $item = $(this);
		var hours = $item.attr("data-val");
		window.location.assign("/events?name=" + rocketLog.name + "&hours=" + hours);
	});

	$(_logConsole).on("loadMore", function() {
		_logConsole.setLoading(true);
		_page += 1;
		getEventsList(_eventName);
	});

	$(_logConsole).on("mouseOverTimestamp", function(e, eventObj) {
		//console.dir(targetObj);
		console.dir(eventObj);
		var offset = $("#chart").width() / 180;


		var ts = parseInt($(eventObj).attr("data-t"), 10) * 1000;
		console.dir(ts);
		console.dir(new Date(ts + 86400));
		index = timeAsTimeSlice(new Date(ts + 86400000));
		index = Math.floor(index);
		var tickLocation = $(".tick:eq(" + index.toString() + ")").offset().left;
		console.dir(tickLocation);
		$("#pointer").css({left: tickLocation});
	});

	$('#myPleaseWait').modal('show');

});




