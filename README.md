Simple Perl gallery
===================

Requires ImageMagick's convert utility in your PATH.

Usage:

    cd /path/to/images
    perl /path/to/gallery/generate.pl .
    cp /path/to/gallery/*.{js,css} .

Clobbers the gallery directory and subdirectories with HTML files. To exclude a
directory from gallery generation, create a .galleryskip file.
