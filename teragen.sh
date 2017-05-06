#!/bin/bash
# Usage : teragen.sh <1G|10G|100G|500G|1TB> <Specs: 3x R4XL(7-vcpu,32GB-RAM,250GB-EBS)> <comments:initial run>


trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

#MR_EXAMPLES_JAR=/usr/hdp/2.2.0.0-2041/hadoop-mapreduce/hadoop-mapreduce-examples.jar
MR_EXAMPLES_JAR=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar

SIZE=$1
START=$(date +%s);

SPECS=$2
COMMENTS=$3

case $SIZE in
    "1T")   ROWS=10000000000;;
    "500G")  ROWS=5000000000;;
    "100G")  ROWS=1000000000;;
    "10G")    ROWS=100000000;;
    "1G")      ROWS=10000000;;
    *)      echo "ERROR : unknown choice. exiting.."
            exit 1;;
esac

echo $SIZE
echo $ROWS

LOGDIR=logs

if [ ! -d "$LOGDIR" ]
then
    mkdir ./$LOGDIR
fi

DATE=`date +%Y-%m-%d:%H:%M:%S`

RESULTSFILE="./$LOGDIR/teragen_results_$DATE"


OUTPUT=/data/sandbox/poc/teragen/${SIZE}-terasort-input

# teragen.sh
# Kill any running MapReduce jobs
mapred job -list | grep job_ | awk ' { system("mapred job -kill " $1) } '
# Delete the output directory
hadoop fs -rm -r -f -skipTrash ${OUTPUT}

# Run teragen
time hadoop jar $MR_EXAMPLES_JAR teragen \
-Dmapreduce.map.log.level=INFO \
-Dmapreduce.reduce.log.level=INFO \
-Dyarn.app.mapreduce.am.log.level=INFO \
-Dio.file.buffer.size=131072 \
-Dmapreduce.map.cpu.vcores=1 \
-Dmapreduce.map.java.opts=-Xmx1536m \
-Dmapreduce.map.maxattempts=1 \
-Dmapreduce.map.memory.mb=2048 \
-Dmapreduce.map.output.compress=true \
-Dmapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.Lz4Codec \
-Dmapreduce.reduce.cpu.vcores=1 \
-Dmapreduce.reduce.java.opts=-Xmx1536m \
-Dmapreduce.reduce.maxattempts=1 \
-Dmapreduce.reduce.memory.mb=2048 \
-Dmapreduce.task.io.sort.factor=100 \
-Dmapreduce.task.io.sort.mb=384 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx768m \
-Dyarn.app.mapreduce.am.resource.mb=1024 \
-Dmapred.map.tasks=92 \
${ROWS} ${OUTPUT} >> $RESULTSFILE 2>&1
 
#-Dmapreduce.map.log.level=TRACE \
#-Dmapreduce.reduce.log.level=TRACE \
#-Dyarn.app.mapreqduce.am.log.level=TRACE \


END=$(date +%s);
secs=$(($END - $START))
DURATION=$(printf '%dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))

echo '**$$** | teragen.sh | $SIZE | $ROWS | $DURATION | $secs | specs:$SPECS | comments:$COMMENTS' >> $RESULTSFILE 2>&1
