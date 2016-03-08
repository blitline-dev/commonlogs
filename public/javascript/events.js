$(function()	{

	var	VIEWSIZE	=	180;

	var	buckets;
	var chartData = {"columns" : []};

	var startTime = new Date(new Date().getTime() - (rocketLog.hours * 3600 * 1000));
	var nowTime = new Date(new Date().getTime());
	var diff = nowTime.getTime() - startTime.getTime();
	var slice = diff / VIEWSIZE;

	function massageData(data) {
		//	Assume	data	in	format	
		//	{ "xxx" : counts...}
		var keys = getKeys(data);
		for (var k=0; k<keys.length; k++) {
			// Insert name into first entry
			var rowData = [keys[k]];
			// Concat count data into array
			rowData = rowData.concat(data[keys[k]]);
			chartData["columns"].push(rowData);
		}
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

	function formatDate(date) {
		var hours = date.getHours();
		var minutes = date.getMinutes();
		var ampm = hours >= 12 ? 'pm' : 'am';
		hours = hours % 12;
		hours = hours ? hours : 12; // the hour '0' should be '12'
		minutes = minutes < 10 ? '0'+minutes : minutes;
		var strTime = hours + ':' + minutes + ' ' + ampm;
		var returnVal;

		if (rocketLog.hours < 24) {
			returnVal = strTime;
		}else {
			returnVal = date.getMonth()+1 + "/" + date.getDate() + " " + strTime;
		}
		return returnVal
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
							return formatDate(timeSliceAsTime(d));
						}
					}
				}
			},
/*
			interaction:	{
				enabled:	false
			},*/
			transition:	{
				duration:	200
			},
			data:	data
		});
	}

	function getEventsData(url) {
		$.get(url, function( data ) {
			massageData(JSON.parse(data));
			drawChart();
			$('#myPleaseWait').modal('hide');
		});
	}
	
	setTimeout( function() {
		getEventsData("/event_list?name=" + rocketLog.name + "&hours=" + rocketLog.hours);
	}, 0 );

	$('#myPleaseWait').modal('show');

});




