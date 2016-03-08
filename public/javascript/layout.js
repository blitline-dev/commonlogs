$(function() {

	function setHours() {
		if(rocketLog && rocketLog.hours) {
			var linkText = $("a[data-val='" + rocketLog.hours.toString() + "']").text();
			if (linkText) {
				$(".hoursMain").text(linkText);
			}
		}
	}

	function setCount() {
		if (rocketLog.count > 0) {
			$(".count").text(Number(rocketLog.count).toLocaleString()  + " items");
		}
	}

	$("#footsearch").submit(function() {
		var searchText = $("#q").val();
		if (searchText && searchText.length < 4) {
			var response = confirm("'" + searchText + "' is a small search term. It may result in MANY return results. Are you sure you want to query that?");
			if (!response) {
				return false;
			}
		}

		$('#myPleaseWait').modal('show');
		// Pre-submit code
	});

	$(".hrs").click(function() {
		var $item = $(this);
		$("#hours").val($item.attr("data-val"));
		$(".hoursMain").text($item.text());
	});

	$(".niceLink").click(function() {
		$('#myPleaseWait').modal('show');
	});

	$("[name='my-checkbox']").bootstrapSwitch();

	setHours();
	setCount();
});

