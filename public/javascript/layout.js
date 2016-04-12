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

			var linkText = $("a[data-val='" + rocketLog.hours.toString() + "']").first().text();
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

	function hookupEvents() {
		var debounce = false;

		$("#search-go").click(function() {
			$("#footsearch").submit();
		});

		$("#footsearch").submit(function() {
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
					$("#footsearch").submit();
					// Yes, continue kind 
				});
			}else {
				debounce = true;
				$("#footsearch").submit();
			}
			return false;

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
