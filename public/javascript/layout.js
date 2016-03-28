$(function() {

	function hideComponents() {
		if ($(".main-content.hide-search").length > 0) {
			$(".search-form").hide();
		}
		if ($(".main-content.hide-tail").length > 0) {
			$(".live-tail").hide();
		}
		if ($(".main-content.hide-hours").length > 0) {
			$(".hours").hide();
		}
		if ($("#q").length > 0 && $("#q").val().length > 0) {
			$(".live-tail").hide();
		}
	}

	function setHours() {
		if(rocketLog && rocketLog.hours) {
			console.log("a[data-val='" + rocketLog.hours.toString() + "']");
			console.dir($("a[data-val='" + rocketLog.hours.toString() + "']"));

			var linkText = $("a[data-val='" + rocketLog.hours.toString() + "']").text();
			console.log(linkText);
			if (linkText) {
				$(".hours-text").html(linkText);
			}
		}
	}

	function setCount() {
		if (rocketLog.count > 0) {
			$(".count").text(Number(rocketLog.count).toLocaleString()	+ " items");
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
		$(".hours-text").text($item.text());
	});

	$(".niceLink").click(function() {
		$('#myPleaseWait').modal('show');
	});

	$("[name='my-checkbox']").bootstrapSwitch();

	setHours();
	setCount();

/*
	$(function(){
		var height = window.innerHeight;
		$('.consoleBox').css('height', height - 100);
		console.log("here");
	});

	//And if the outer div has no set specific height set.. 
	$(window).resize(function(){
		var height = window.innerHeight;
		$('.consoleBox').css('height', height - 100);
		console.log("here" + height.toString());

	});
*/

	$('.confirmDelete').on('click', function (e) {
		var _this = $(e.target);
		var form = $(_this).find("form");
		console.dir(form)
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
	hideComponents();
});
