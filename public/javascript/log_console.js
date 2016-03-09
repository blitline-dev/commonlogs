function LogConsole () {
}

LogConsole.prototype = {
	cleanup: function () {
		var numItems = $('.r').length;
		if (numItems > 10000) {
			$("#console").find(".r:lt(1000)").remove();
		}
	},
	addRows: function(data) {
		var row;
		var rowDate;
		var href;
		var html;
		var allHtml = [];

		for(var i = 0; i < data.length; i++) {
			row = data[i];

			if (row[0].indexOf("T") > -1) {
				rowDate = row[0].substring(5,19).replace("T","-");
			}else {
				rowDate = Utils.formatDate(new Date(parseInt(row[0], 10) * 1000));
			}


			href = "/context?name=" + rocketLog.name + "&time=" + row[0] + "&server=" + row[2] + "&seq=" + row[1] + "&file=" + row[4];
			html = [
				"<li class='r' data-rsyspref='" + row[0] + " " + row[1] + " " + row[2] + "'>",
				"<span class='muted'>" + rowDate + "&nbsp;</span>",
				"<a class='niceLink' href='" + href + "'>" + row[2] + "</a>",
				"<span>&nbsp;" + row[3].toString().autoLink({ target: "_blank", rel: "nofollow", class: "al" }) + "</span>",
			];

			allHtml.push(html.join(""));
		}

		$newNode = $(allHtml.join(""));
		$("#console").append($newNode);
		this.cleanup();
		$(this).trigger("afterAppend");
	},
	clear: function() {
		$("#console").empty();
	}
};
 

