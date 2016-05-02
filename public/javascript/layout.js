$(function() {
	debounce = false;

	function hideComponents() {
		if ($(".main-content.hide-search").length > 0) {
			$(".search-form").hide();
		}

		if ($(".main-content.hide-tail").length > 0) {
			$(".live-tail").hide();
		}

		if ($(".main-content.hide-hours").length > 0) {
			$(".hours").hide();
			$(".hours-bottom").hide();
		}

		if ($(".main-content.hide-hours-top").length > 0) {
			$(".hours").hide();
		}

		if ($(".main-content.hide-hours-bottom").length > 0) {
			$(".hours-bottom").hide();
		}

		if ($("#q").length > 0 && $("#q").val().length > 0) {
			$(".live-tail").hide();
		}
	}

	function setHours() {
		if(rocketLog && rocketLog.hours) {
			if ((rocketLog.hours).indexOf("-") > 0) {
				setCustomTime();
				$(".hours-text").html("Custom");
			} else {
				var linkText = $("a[data-val='" + rocketLog.hours.toString() + "']").first().text();
				if (linkText) {
					$(".hours-text").html(linkText);
				}
			}
		}
	}

	function setCustomTime() {
		var times = rocketLog.hours.split("-");
		var startTime = new Date(1000 * parseInt(times[0]));
		var endTime = new Date(1000 * parseInt(times[1]));

		 $("#startTime").val(startTime.toString("MMMM d, HH:mm tt"));
		 $("#endTime").val(endTime.toString("MMMM d, HH:mm tt"));
	}

	function customTime() {
		var startVal = $("#startTime").val();
		var endVal = $("#endTime").val();
		var startTime = null;
		var endTime = null;

		if (startVal) {
			startTime = Date.parse(startVal);
		}
		if (endVal) {
			endTime = Date.parse(endVal);
		}else {
			endTime = Math.round(new Date());
		}

		if (startTime < endTime) {
			var startSec = startTime.getTime() / 1000;
			var endSec = endTime.getTime() / 1000;
			var range = startSec.toString() + "-" + endSec.toString();
			$("#hours").val(range);
			$("#footsearch").submit();
		}

	}

	function setCount() {
		if (rocketLog.count > 0) {
			$(".count").text(Number(rocketLog.count).toLocaleString()	+ " items");
		}
	}

	function performSearch() {
		if (debounce) {
			return true;
		}
		var searchText = $("#q").val();
		if (searchText && searchText.length < 4) {
			swal({
				title: 'Are you sure?',
				text: "'" + searchText + "' is a small search term. It may result in MANY return results. Are you sure you want to query that?",
				type: 'warning',
				showCancelButton: true,
				confirmButtonColor: '#DD6B55',
				confirmButtonText: 'Yes, Go!',
				closeOnConfirm: false,
			}, function () {
				$('#myPleaseWait').modal('show');
				debounce = true;
				return true;
				// Yes, continue kind 
			});
		}else {
			debounce = true;
			return true;
		}
		return false;
	}

	function hookupEvents() {
		debounce = false;

    $('#customRange input').on('keydown', function(e) {
        if (e.which == 13) {
          customTime();
        }
    });

		$("#customGo").click(function() {
			customTime();
		});

		$("#search-go").click(function() {
			$("#footsearch").submit();
		});

		$("#footsearch").submit(function() {
			return performSearch();
		});

		$(".search-hrs").click(function() {
			var $item = $(this);
			$("#hours").val($item.attr("data-val"));
			$(".hours-text").text($item.text());
			$("#footsearch").submit();
		});

		$(".niceLink").click(function() {
			$('#myPleaseWait').modal('show');
		});

		$("[name='my-checkbox']").bootstrapSwitch();

		$('.confirmDelete').on('click', function (e) {
			var _this = $(e.target);
			var form = $(_this).find("form");
			swal({
				title: 'Are you sure?',
				text: 'You will not be able to recover this item!',
				type: 'warning',
				showCancelButton: true,
				confirmButtonColor: '#DD6B55',
				confirmButtonText: 'Yes, delete it!',
				closeOnConfirm: false,
			}, function () {
					$(_this).find('form').submit();
					swal('Deleted!', 'Your imaginary file has been deleted!', 'success');
				});
			});

		$('[data-toggle="popover"]').popover();
	}

	setHours();
	setCount();
	hookupEvents();
	hideComponents();

});
