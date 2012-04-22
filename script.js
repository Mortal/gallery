window.onkeydown = function (ev) {
	if (!ev) ev = window.event;
	var k = ev.keyCode;
	if (k == 37) // left
		location.href = document.getElementById('prev').href;
	if (k == 38 || k == 27 || k == 8) // up || escape || backspace
		location.href = ".";
	if (k == 39 || k == 32) // right || space
		location.href = document.getElementById('next').href;
};
