$(function()	{
	var	_VIEWSIZE = 180;
	var _chartData = { "columns" : [], "maxY" : 0, "id_keys" : {} };
	var _logConsole = new LogConsole();
	var _startTime;
	var _slice;
	var _eventName;
	var _page = 0;
	var _customRange = null;
	var _legendSelected = null;

	function resetPointer() {
		$("#pointer").hide();
		$("#pointer").css({ left: -100});
	}

	function eventChanged($el) {
		var name = $el.attr("data-group");
		var url = "events?name=" + encodeURIComponent(name) + "&hours=" + commonLog.hours.toString();
		window.location = url;
	}

	function massageData(data) {
		//	Assume	data	in	format	
		//	{ "xxx" : counts...}
		var keys = Utils.getKeys(data);
		var maxAll = 0;
		for (var k=0; k<keys.length; k++) {
			var sum = Utils.sumValues(data[keys[k]]);
			var max = Utils.maxValue(data[keys[k]]);

			_chartData.id_keys[keys[k]] = { "maxY" : max };

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

	function drawChart(colors) {
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
			type: 'spline',
			color: function (color, d) {
            	// d will be 'id' when called for legends
            	var cname = d.toString().split(" ")[0];
            	if (cname && colors[cname] != null) {
	            	return colors[cname];
            	}

            	cname = d.id.split(" ")[0];
                if (cname && colors[cname] != null) {
	            	return colors[cname];
            	}

            	return;
        	}
		};

		data["columns"] = _chartData.columns;
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
			tooltip: {
  			grouped: false
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
							return Utils.formatDate(timeSliceAsTime(d), commonLog.hours);
						}
					}
				}
			},
			legend: {
				item: {
					onclick: function(id) { legendClick(chart, id) },
				}
			},
			onrendered: chartRendered,
			transition:	{
				duration:	200
			},
			data:	data
		});

		chart.flush();
	}

	function chartRendered() {
		// Chart Rendered Event
	}

	function legendClick(chart, id) {
		if (_legendSelected == id) {
	    chart.show();
	    _logConsole.clear();
	    _legendSelected = null;
	    chart.max( { "y" : _chartData.maxY });
	    setTimeout(function() {
				chart.flush();	    
		    chart.resize();
		  }, 300);
	    return;
		}else {
	    chart.hide();
	    chart.show(id);
	    chart.legend.show();
			chart.axis.max( { "y" : _chartData.id_keys[id.split(" ")[0]].maxY });
	    setTimeout(function() {
				chart.flush();	    
		    chart.resize();
		  }, 300);
		}

		$('#myPleaseWait').modal('show');
		_logConsole.clear();
		resetPointer();
		_page = 0;
		_eventName = id.split(" ")[0];
		getEventsList(_eventName);
		_legendSelected = id;

	}

	function getEventsData(url) {
		$.get(url, function( rawData ) {
			try {
				var data = JSON.parse(rawData);
				if (jQuery.isEmptyObject(data["event_data"]) || data["event_data"] === "{}") {
					showEmptyHelp();
					afterRender();
					return;
				}

				start_timestamp = data["st"];
				end_timestamp = data["et"];
				event_data = data["event_data"];
				_startTime = start_timestamp;
				_slice = (end_timestamp - _startTime) / _VIEWSIZE;
				var colors = data["colors"] || {};

				massageData(event_data);
				drawChart(colors);
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

		var url = "/events/event_list?name=" + encodeURIComponent(commonLog.name) + "&event_name=" + encodeURIComponent(eventName) + "&page=" + _page;


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

	function showEmptyHelp() {
		$(".main-content").hide();
		$("#belowChart").show();
	}

	function afterRender() {
		$('#myPleaseWait').modal('hide');
	}

	function handleCustomTimeRange() {
		var hours = $("#hours").val();
		var st = hours.split("-")[0];
		var et = hours.split("-")[1];
		window.location.assign("events?name=" + encodeURIComponent(commonLog.name) + "&st=" + st + "&et=" + et);
	}

	// Load data after page loads
	setTimeout( function() {
		var hours = Utils.getParameterByName("hours");
		var st = Utils.getParameterByName("st");
		var et = Utils.getParameterByName("et");

		var url = "/events/event_counts?name=" + commonLog.name;
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
		window.location.assign("events?name=" + encodeURIComponent(commonLog.name) + "&hours=" + hours);
	});

	$(".group").click(function() {
		eventChanged($(this));
		return false;
	});

	$("#customGo").on("event:customTimeSet", function(e) {
  	handleCustomTimeRange();		
	});

	$(_logConsole).on("loadMore", function() {
		_logConsole.setLoading(true);
		_page += 1;
		getEventsList(_eventName);
	});

	$(_logConsole).on("mouseOverTimestamp", function(e, eventObj) {
		//console.dir(targetObj);
		var offset = $("#chart").width() / 180;


		var ts = parseInt($(eventObj).attr("data-t"), 10) * 1000;
		index = timeAsTimeSlice(new Date(ts));
		index = Math.floor(index);
		var tickItem = $(".tick:eq(" + index.toString() + ")");
		if (tickItem && tickItem.length > 0) {
			var tickLocationNode = $(".tick:eq(" + index.toString() + ")");
			if (tickLocationNode) {
				tickLocation = tickLocationNode.offset().left;
				$("#pointer").css({left: tickLocation});
			}
		}
	});

	$('#myPleaseWait').modal('show');

});




