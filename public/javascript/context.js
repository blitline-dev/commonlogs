$(function() {
	var contextItem = $("a[data_id='"+window.seq.toString()+"']");
	var consoleDiv = $("#console");

	contextItem.parent().attr("style", "background-color: #ffff00; color: #000;");
	window.scrollTo(0, (consoleDiv.height() / 2) - 350);
	
});

