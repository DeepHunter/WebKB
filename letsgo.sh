

./dataprocess.sh

#evaluate
shuffle() {
  awk 'BEGIN{srand();}{print rand()"\t"$0}' |LC_CTYPE=C sort -n |LC_CTYPE=C cut -f2-
}


sort webkb.filter | cut -f4 | awk 'BEGIN{a=0;}{print "_*" a " " $0; a++;}'  > sen2vec_train
sort webkb.filter | cut -f2,3 > label

gcc word2vec.c -o sen2vec -lm -pthread -O3 -march=native -funroll-loops

time ./sen2vec -train sen2vec_train -output vectors_cbow.txt -cbow 1 -size 200 -window 8 -negative 10 -hs 0 -sample 1e-3 \
-threads 5 -binary 0 -iter 20 -min-count 1 -sentence-vectors 1
time ./sen2vec -train sen2vec_train -output vectors_sg.txt -cbow 0 -size 200 -window 1 -negative 10 -hs 0 -sample 1e-3 \
-threads 5 -binary 0 -iter 20 -min-count 1 -sentence-vectors 1
grep '_\*' vectors_cbow.txt > sentence_vectors_cbow.txt
grep '_\*' vectors_sg.txt > sentence_vectors_sg.txt

wget http://www.csie.ntu.edu.tw/~cjlin/liblinear/liblinear-1.96.zip
unzip liblinear-1.96.zip
cd liblinear-1.96
make
cd ..

#don't know why this happened, the order of documents changes.
cut -c 3- sentence_vectors_cbow.txt | sort -n > vc.txt
cut -c 3- sentence_vectors_sg.txt | sort -n | cut -d" " -f2- > vsg.txt
paste vc.txt vsg.txt > vector_rep.txt

wc -l  vector_rep.txt 

cat vector_rep.txt | awk 'BEGIN{a=0;}{for (b=1; b<NF; b++) printf b ":" $(b+1) " "; print ""; a++;}' > sentence
paste label sentence > data 

rm predict.sen2vec
rm ground.truth
for i in cornell texas washington wisconsin; do
  grep -v "\t$i\t" data | grep -v "department\t"  |  cut -f1,3 | tr '\t' ' ' | sed -e 's/course/1/g' -e 's/faculty/2/g' -e 's/project/3/g' -e 's/staff/4/g' -e 's/student/5/g' > train.txt
  grep "\t$i\t"  data | grep -v "department\t"  |  cut -f1,3  | tr '\t' ' ' | sed -e 's/course/1/g' -e 's/faculty/2/g' -e 's/project/3/g' -e 's/staff/4/g' -e 's/student/5/g' > test.txt
  ./liblinear-1.96/train -s 0 -c 0.1 -q train.txt model.logreg
  ./liblinear-1.96/predict -b 1 test.txt  model.logreg predict.$i.sen2vec
  cat test.txt | awk 'BEGIN{a=0;}{print $1; a++;}' >> ground.truth
  tail -n +2 predict.$i.sen2vec | awk 'BEGIN{a=0;}{print $1; a++;}'>> predict.sen2vec 
done

paste predict.sen2vec ground.truth | awk 'BEGIN{cn=0; corr=0;} {if ($1 == $2) corr++;cn++;} END{print "sen2vec accuracy: " corr/cn*100 "%";}'
