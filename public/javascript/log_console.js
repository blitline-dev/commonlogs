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
	escapeHtml: function(s) {
		var n = s;
    n = n.replace(/&/g, '&amp;');
    n = n.replace(/</g, '&lt;');
    n = n.replace(/>/g, '&gt;');
    n = n.replace(/"/g, '&quot;');
    return n;
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

			var rowText = row[3].toString();

			if (rowText && rowText.charAt(0) === "{") {
				try {
					v = JSON.parse(rowText);
					if (v) {
						rowText = JSON.stringify(v, null, 2);
						rowText = "<pre>" + rowText + "</pre>";
					}
				}catch(ex) {
					rowText = _this.escapeHtml(row[3].toString());
				}
			}else {
				rowText = _this.escapeHtml(row[3].toString());
			}

			rowUnixDate = parseInt(row[0], 10);
			rowDate = Utils.formatDate(new Date(rowUnixDate * 1000));


			href = "context?name=" + commonLog.name + "&time=" + row[0] + "&server=" + row[2] + "&seq=" + row[1] + "&file=" + row[4];

			if (rowText.includes("[[[")) {
				rowText = this.highlightAnsi(rowText);
			}

			if (rowText.includes("[[*html.span.fructy]]")) {
				rowText = rowText.replace(/\[\[\*html\.span\.fructy\]\]/g, "<span class='fructy'>");
				rowText = rowText.replace(/\[\[\*html\.end\.span\]\]/g, "</span>");
			}



			html = [
				"<li class='r ts' data-t='" + rowUnixDate.toString() + "' data-r='" + row[1].toString() + "'>",
				"<span class='muted'>" + rowDate + "&nbsp;</span>",
				"<a class='text-primary' href='" + href + "'>" + row[2] + "</a>",
				"<span>&nbsp;" + rowText.autoLink({ target: "_blank", rel: "nofollow", class: "text-info" }) + "</span>",
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
	softClear: function() {
		$("#console").find('li:not(:last)').remove();
	},
	setLoading: function(isLoading) {
		this.skipLoadMoreEvent = isLoading;
	},
	highlightAnsi: function(str) {
		var v = str;
		v = str.replace(/\[\[\[span\:(.*?)\]\]\]/g, "<span style='$1'>");
		v = v.replace(/\[\[\[b\:\]\]\]/g, "<b>");
		v = v.replace(/\[\[\[b\]\]\]/g, "</b>");
		v = v.replace(/\[\[\[span\]\]\]/g, "</span>");

		return v;
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
		if ($("#console").html().length < 10) {
			$("#console").html("<div class='noResults'>&nbsp;No Results Found</div>")
		}
	}

};


