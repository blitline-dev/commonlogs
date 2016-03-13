$(function(){
	var _colorPicker = null;

	_colorPicker = $('.demo2').colorpicker({
		format: "hex",
		align: "left",
		color: '#'+Math.floor(Math.random()*16777215).toString(16)
	});

	$(".add_event").click(function() {
		setTimeout(function() {
			_colorPicker.colorpicker('setValue', '#'+Math.floor(Math.random()*16777215).toString(16));
		}, 0);
	})
});
