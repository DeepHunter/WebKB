function normalize_text {
  LC_ALL=C tr '\r' ' ' | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C tr '\t' ' ' | LC_ALL=C tr '\n' ' ' | LC_ALL=C sed -e 's/<[^>]*>//g' -e 's/[^a-z0-9]/ /g' -e 's/  */ /g'
}

wget http://www.cs.cmu.edu/afs/cs.cmu.edu/project/theo-20/www/data/webkb-data.gtar.gz
tar -xvf webkb-data.gtar.gz
mv webkb webkb-data

rm webkb-data/course/washington/http:^^www.cs.washington.edu^education^courses^590B^
rm webkb-data/course/washington/http:^^www.cs.washington.edu^education^courses^457
rm webkb.data
cd webkb-data
for i in course faculty student project staff department; do
  for j in cornell texas washington wisconsin; do
    for k in `ls $i/$j`; do
      printf "$k\t$i\t$j\t" | tr 'A-Z' 'a-z'   >> ../webkb.data;
      cat $i/$j/$k | normalize_text >> ../webkb.data;
    done 
  done
done

cat ../webkb.data | sed -e 's/\^	/	/g' | sed -e 's/	department	/	course	/g'> ../webkb.all
#cat ../webkb.data | sed -e 's/\^	/	/g' > ../webkb.all

cd ..
wget http://www.cs.umd.edu/~sen/lbc-proj/data/WebKB.tgz
tar -zxf WebKB.tgz

cd WebKB
cat cornell.content texas.content washington.content wisconsin.content | cut -f1 | tr '\/' '^' | tr 'A-Z' 'a-z' > ../webkb.content
cat cornell.cites texas.cites washington.cites wisconsin.cites | tr '\/' '^' | tr 'A-Z' 'a-z' > ../webkb.cites

cd ..
rm webkb.filter
rm webkb.log
#cp webkb.all  webkb.filter
cat webkb.content | while read line
do
grep "$line\t" webkb.all >> webkb.filter

printf "$line\t" >> webkb.log
grep "$line\t" webkb.all | wc -l >> webkb.log
done


