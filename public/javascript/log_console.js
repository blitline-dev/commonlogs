function LogConsole () {
}

LogConsole.prototype = {
	cleanup: function () {
		var numItems = $('.r').length;
		if (numItems > 10000) {
			$("#console").find(".r:lt(1000)").remove();
		}
	},
	clearLoading: function() {
		$(".liEndCap").remove();
	},
	addRows: function(data, eventName) {
		var row;
		var rowDate;
		var href;
		var html;
		var allHtml = [];
		var rowUnixDate;
		var _this = this;

		this.clearLoading();

		if (data.length === 0) {
			this.disableLoadMoreEvent = true;
			return;
		}

		for(var i = 0; i < data.length; i++) {
			row = data[i];
			if (null == row[3]) {
				row[3] = "";
			}
			if (null == row[2]) {
				row[2] = "";
			}

			if (row[3] && row[3].toString().charAt(0) === "{") {
				try {
					v = JSON.parse(row[3]);
					if (v) {
						row[3] = "<pre>" + JSON.stringify(v, null, 2) + "</pre>";
					}
				}catch(ex) {
					// Do Nothing. Not JSON...move on
				}
			}

			
			rowUnixDate = parseInt(row[0], 10);
			rowDate = Utils.formatDate(new Date(rowUnixDate * 1000));
			

			href = "context?name=" + commonLog.name + "&time=" + row[0] + "&server=" + row[2] + "&seq=" + row[1] + "&file=" + row[4];
			html = [
				"<li class='r ts' data-t='" + rowUnixDate.toString() + "' data-r='" + row[1].toString() + "'>",
				"<span class='muted'>" + rowDate + "&nbsp;</span>",
				"<a class='text-primary' href='" + href + "'>" + row[2] + "</a>",
				"<span>&nbsp;" + row[3].autoLink({ target: "_blank", rel: "nofollow", class: "text-info" }) + "</span>",
				"</li>"
			];

			if (eventName) {
				html.splice(1, 0, "<span class='label label-primary'>" + eventName + "</span><span>&nbsp;&nbsp;<span>");
			}
			allHtml.push(html.join(""));
		}


		$newNode = $(allHtml.join(""));
		$newNode.mouseenter(function(e) {
			_this.mouseEnterTimestamp(e, this);
		});
		
		$("#console").append($newNode);		
		
		if (eventName) {
			$("#console").append("<li class='liEndCap'><img class='spin' src='spin.svg'>&nbsp;Looking around for more...</li>");
		}
		this.cleanup();
		$(this).trigger("afterAppend");
		this.activateInfinityScroll();

	},
	clear: function() {
		$("#console").empty();
		this.disableLoadMoreEvent = false;

	},
	setLoading: function(isLoading) {
		this.skipLoadMoreEvent = isLoading;
	},
	// Use the browser's built-in functionality to quickly and safely escape the
	// string
	escapeHtml: function(str) {
    var div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
	},
	activateInfinityScroll: function() {
		var _this = this;

		if (!this.infinityScrollActivated) {
			$(window).on('scroll', function(){
				if( $(window).scrollTop() + 100 > $(document).height() - $(window).height() && !_this.skipLoadMoreEvent && !_this.disableLoadMoreEvent ) {
					$(_this).trigger("loadMore");
				}
			}).scroll();
			this.infinityScrollActivated = true;
		}
	},
	mouseEnterTimestamp: function(e, eventObj) {
		$(this).trigger("mouseOverTimestamp", [eventObj]);
	},
	setEmpty: function() {
		$("#console").html("<div class='noResults'><i class=\"fa fa-eye-slash\"></i>&nbsp;No Results Found</div>")
	}

};
 

