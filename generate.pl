#!/usr/bin/env perl

# vim:set sw=4 sts=4 ts=4 noet:

use warnings;
use strict;

sub basepath {
	my ($dir) = @_;
	$dir .= '/';
	$dir =~ s/^\.\///;
	$dir =~ s/[^\/]+/../g;
	return $dir;
}

sub direntries {
	my ($dir) = @_;
	my $dh;
	if (!opendir($dh, $dir)) {
		warn "Can't opendir $dir: $!";
		return ();
	}
	my @direntries = grep { !/^\./ } readdir($dh);
	closedir $dh;
	return sort @direntries;
}

sub subdirs {
	my ($dir) = @_;
	return reverse grep { !/^thumbs$/ && -d "$dir/$_" && !-e "$dir/$_/.galleryskip" } direntries $dir;
}

sub imagefiles {
	my ($dir) = @_;
	return grep { /\.jpe?g$/i } direntries $dir;
}

sub slurpfile {
	my ($filename) = @_;
	my $fd;
	if (!open($fd, '<', $filename)) {
		warn "Couldn't open $filename for reading: $!";
		return '';
	}
	my $contents;
	{
		local $/ = undef;
		$contents = <$fd>;
	}
	close $fd;
	return $contents;
}

sub magic_marker { '<!-- autogenerated image gallery -->'; }

sub may_overwrite {
	my ($filename) = @_;
	my $contents = slurpfile $filename;
	return -1 < index $contents, magic_marker;
}

sub thumbpath {
	my ($image) = @_;
	return "thumbs/$image";
}

sub checkthumbnails {
	my ($dir, @images) = @_;
	if (!-e "$dir/thumbs") {
		if (!mkdir("$dir/thumbs")) {
			warn "Couldn't create directory $dir/thumbs: $!";
			return;
		}
	}
	for my $img (@images) {
		checkthumbnail($dir, $img);
	}
}

sub checkthumbnail {
	my ($dir, $img) = @_;
	my $thumbpath = thumbpath $img;
	if (-e "$dir/$thumbpath") {
		return;
	}
	print "Thumbnailing $dir/$thumbpath\n";
	system 'convert', '-resize', '200x200', "$dir/$img", "$dir/$thumbpath";
}

sub viewpages {
	my ($dir, @pages) = @_;
	my $prev = [];
	my $cur = shift @pages;
	for my $next (@pages, []) {
		viewpage($dir, $prev, $cur, $next);
		$prev = $cur;
		$cur = $next;
	}
}

sub viewpagename {
	my ($name) = @_;
	$name =~ s/\.[^.]*$|$/\.html/;
	return $name;
}

sub viewpage {
	my ($dir, $prev, $cur, $next) = @_;
	my $basepath = basepath $dir;
	my $htmlname = viewpagename $cur;
	$prev = ('' eq ref $prev) ? viewpagename($prev) : '.';
	$next = ('' eq ref $next) ? viewpagename($next) : '.';
	if (-e "$dir/$htmlname") { return; }
	print "Generate view page $dir/$htmlname\n";
	my $fh;
	open $fh, '>', "$dir/$htmlname";
	print $fh <<HTML;
<!DOCTYPE html><html><head><script type=\"text/javascript\" src=\"${basepath}script.js\"></script>
<link rel=\"stylesheet\" type=\"text/css\" href=\"${basepath}imagestyle.css\" /></head>
<body><a href=\"$prev\" id=\"prev\">&larr;</a>
<img src=\"$cur\" /><a href=\"$next\" id=\"next\">&rarr;</a></body></html>
HTML
	close $fh;
}

sub generate_for_directory {
	my ($dir) = @_;

	my $index = "$dir/index.html";
	if (-e $index) {
		if (!may_overwrite($index)) {
			warn "Skipping $dir since an index.html already exists";
			return;
		}
	}

	my @subdirs = subdirs $dir;
	for my $subdir (@subdirs) {
		generate_for_directory("$dir/$subdir");
	}

	my $fd;
	if (!open($fd, '>', $index)) {
		warn "Couldn't open $index for writing: $!";
		return;
	}
	print "Generating $index\n";
	printheader($fd, $dir);
	my @subindexes = grep { -e "$dir/$_/index.html" } @subdirs;
	if (@subindexes) {
		printsubgalleries($fd, @subindexes);
	}
	my @images = imagefiles $dir;
	if (@images) {
		checkthumbnails $dir, @images;
		viewpages $dir, @images;
		printimages($fd, @images);
	}
	printfooter($fd);
}

sub printheader {
	my ($fd, $dir) = @_;
	my $style = basepath($dir).'style.css';
	my $mm = magic_marker;
	print $fd <<HTML;
<!DOCTYPE html>
$mm
<html>
<head>
<meta charset="utf-8" />
<title>Galleri af $dir</title>
<link rel="stylesheet" type="text/css" href="$style" />
</head>
<body>
HTML
}

sub printsubgalleries {
	my ($fd, @dirs) = @_;
	print $fd "<ul id=\"subgalleries\">\n";
	for my $dir (@dirs) {
		print $fd "<li><a href=\"$dir/\">$dir</a></li>\n";
	}
	print $fd "</ul>\n";
}

sub printimages {
	my ($fd, @images) = @_;
	print $fd "<ul id=\"images\">\n";
	for my $img (@images) {
		my $page = viewpagename $img;
		print $fd "<li><a href=\"$page\"><img src=\"".thumbpath($img)."\" /></a></li>\n";
	}
	print $fd "</ul>\n";
}

sub printfooter {
	my ($fd) = @_;
	print $fd <<HTML;
</body>
</html>
HTML
}

for my $arg (@ARGV) {
	generate_for_directory $arg;
}
