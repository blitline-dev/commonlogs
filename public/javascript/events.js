$(function()	{

	var	VIEWSIZE	=	180;

	var	buckets;
	var chartData = {"columns" : []};

	var startTime = new Date(new Date().getTime() - (rocketLog.hours * 3600 * 1000));
	var nowTime = new Date(new Date().getTime());
	var diff = nowTime.getTime() - startTime.getTime();
	var slice = diff / VIEWSIZE;
	var logConsole = new LogConsole();

	function massageData(data) {
		//	Assume	data	in	format	
		//	{ "xxx" : counts...}
		var keys = getKeys(data);
		for (var k=0; k<keys.length; k++) {
			var sum = sumValues(data[keys[k]]);
			if (sum > 0) {
				// Insert name into first entry
				var rowData = [keys[k] + " (" + sum.toString() + ")"];
				// Concat count data into array
				rowData = rowData.concat(data[keys[k]]);
				chartData["columns"].push(rowData);
			}
		}
	}

	function sumValues(array) {
		var total = 0;
		for(var i=0; i<array.length; i++) {
			total += array[i];
		}
		return total;
	}

	function timeSliceAsTime(timeSliceIndex) {
		var dateTime = startTime.getTime() + (timeSliceIndex * slice);
		return new Date(dateTime);
	}

	function getKeys(obj) {
		var keys = [], name;
		for (name in obj) {
				if (obj.hasOwnProperty(name)) {
						keys.push(name);
				}
		}
		return keys;
	}

/*
	function groupBuckets() {
		for(var i=0; i<buckets.length; i++) {
			var bucket = buckets[index];
			var group = {};
			if (bucket) {
				for(var j=0; j < bucket.length; j++) {
					var row = bucket[j];
					var name = row[0];
					if (eventNames.indexOf(name) > -1) {
						eventNames.push(name);
					}
					if (group[name]) {
						group[name] += 1;
					}else {
						group[name] = 1;
					}
				}
			}
			bucketGroups.push(group);
		}
	}
*/
	function drawChart() {
		var data	=	{
		};

		data["columns"] = chartData.columns;

		var	chart	=	c3.generate({
			bindto:	'#chart',
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
					tick: {
						count: 5,
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
			transition:	{
				duration:	200
			},
			data:	data
		});
	}

	function legendClick(id) {
		logConsole.clear();
		var eventName = id.split(" ")[0];
		getEventsList(eventName);
	}

	function getEventsData(url) {
		$.get(url, function( data ) {
			try {
				if (jQuery.isEmptyObject(data) || data === "{}") {
					showEmptyChart();
					afterRender();
					return;
				}
				massageData(JSON.parse(data));
				drawChart();
				afterRender();
			}catch(ex) {
				console.log(ex.stack);
			}
		});
	}

	function getEventsList(eventName) {
		var url = "/event_list?event_name=" + eventName + "&hours=" + rocketLog.hours + "&name=" + rocketLog.name;

		$.get(url, function( data ) {
			try {
				logConsole.addRows(JSON.parse(data));
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

	setTimeout( function() {
		getEventsData("/event_counts?name=" + rocketLog.name + "&hours=" + rocketLog.hours);
	}, 0 );

	$('#myPleaseWait').modal('show');

});




