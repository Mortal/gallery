window.onkeydown = function (ev) {
	if (!ev) ev = window.event;
	if (ev.keyCode == 37) // left
		location.href = document.getElementById('prev').href;
	if (ev.keyCode == 38) // up
		location.href = ".";
	if (ev.keyCode == 39) // right
		location.href = document.getElementById('next').href;
};
