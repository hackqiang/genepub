#!/bin/bash

rm -rf output
mkdir -p output/META-INF
mkdir -p output/OEBPS/{audio,images,text}


##0. copy resource
cp -rf epub_template/mimetype output
cp -rf epub_template/META-INF/container.xml output/META-INF
cp -rf epub_template/OEBPS/styles output/OEBPS

find fake_res -name *.mp3 | xargs -i{X} cp {X} output/OEBPS/audio
find fake_res -name *.png | xargs -i{X} cp {X} output/OEBPS/images
find fake_res -name *.txt | xargs -i{X} cp {X} output/OEBPS/text

##1. generate cover
cp epub_template/OEBPS/text/cover.xhtml output/OEBPS/text


#2. generate foreword.xhtml
cp epub_template/OEBPS/text/foreword.xhtml output/OEBPS/text
####TODO: add cover infor


##2. generate chapter
for file in `ls output/OEBPS/audio`
do
	chapter_name=`basename $file .mp3`
	echo $chapter_name
	cp epub_template/OEBPS/text/chapter.xhtml output/OEBPS/text/chapter-$chapter_name.xhtml
	sed -i "s/\[CHAPTER_NAME\]/$chapter_name/g" output/OEBPS/text/chapter-$chapter_name.xhtml
	
	if [ -f  output/OEBPS/text/$chapter_name.txt ]; then
		sed -i ':t;N;s/\r\n/< \/br>/;b t' output/OEBPS/text/$chapter_name.txt
		sed -i ':t;N;s/\n/< \/br>/;b t' output/OEBPS/text/$chapter_name.txt
		#####TODO: fix long sercribe
		sed -i "s/[DESCRIPTION]/`cat output/OEBPS/text/$chapter_name.txt`/g" output/OEBPS/text/chapter-$chapter_name.xhtml
		rm output/OEBPS/text/$chapter_name.txt
	fi
done

rm output/OEBPS/text/*.txt

##3. generate <manifest> in content.opf
cp epub_template/OEBPS/content.opf output/OEBPS
echo '  <manifest>' >> output/OEBPS/content.opf
for file in `ls output/OEBPS/audio`
do
	echo "<item href=\"audio/$file\" id=\"$file\" media-type=\"audio/mpeg\" />" >> output/OEBPS/content.opf
done

for file in `ls output/OEBPS/images`
do
	echo "<item href=\"images/$file\" id=\"$file\" media-type=\"image/png\" />" >> output/OEBPS/content.opf
done

for file in `ls output/OEBPS/styles`
do
	echo "<item href=\"styles/$file\" id=\"$file\" media-type=\"text/css\" />" >> output/OEBPS/content.opf
done

for file in `ls output/OEBPS/text`
do
	echo "<item href=\"text/$file\" id=\"$file\" media-type=\"application/xhtml+xml\" />" >> output/OEBPS/content.opf
done

echo "<item href=\"toc.ncx\" id=\"ncx\" media-type=\"application/x-dtbncx+xml\" />" >> output/OEBPS/content.opf
echo "  </manifest>" >> output/OEBPS/content.opf


##4. generate <spine> in content.opf
echo '  <spine toc="ncx">' >> output/OEBPS/content.opf

echo "<itemref idref=\"cover.xhtml\" />" >> output/OEBPS/content.opf
echo "<itemref idref=\"foreword.xhtml\" />" >> output/OEBPS/content.opf
    
for file in `ls output/OEBPS/audio`
do
	chapter_name=`basename $file .mp3`
	echo $chapter_name
	echo "<itemref idref=\"chapter-$chapter_name.xhtml\" />" >> output/OEBPS/content.opf
done
echo '  </spine>' >> output/OEBPS/content.opf

##finish content.opf
echo '</package>' >> output/OEBPS/content.opf


##5. generate toc.ncx
cp epub_template/OEBPS/toc.ncx output/OEBPS

order=3
for file in `ls output/OEBPS/audio`
do
	chapter_name=`basename $file .mp3`
	echo $chapter_name $order
	echo "<navPoint id=\"navPoint-$chapter_name\" playOrder=\"$order\">" >> output/OEBPS/toc.ncx
	echo "  <navLabel>" >> output/OEBPS/toc.ncx
	echo "<text>$chapter_name</text>" >> output/OEBPS/toc.ncx
	echo " </navLabel>" >> output/OEBPS/toc.ncx
	echo "<content src=\"text/chapter-$chapter_name.xhtml\" />" >> output/OEBPS/toc.ncx
	echo "</navPoint>" >> output/OEBPS/toc.ncx
	let order=$order+1
done

echo '</navMap>' >> output/OEBPS/toc.ncx
echo '</ncx>' >> output/OEBPS/toc.ncx


##6. pack epub
cd output
zip -r ../test.epub *



