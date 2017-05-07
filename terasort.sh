#!/bin/bash
# Usage : terasort.sh --size=<1G|10G|100G|500G|1TB> --specs='3x R4XL(7-vcpu,32GB-RAM,250GB-EBS)' --comments='initial run'>

trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

MR_EXAMPLES_JAR=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar

START=$(date +%s);

# Parsing the input arguements
for i in "$@"
do
case $i in
    -s=*|--size=*)
    __SIZE="${i#*=}"
    SIZE=${__SIZE:-'1G'}
    shift # past argument=value
    ;;
    -sp=*|--spec=*)
    __SPECS="${i#*=}"
    SPECS=${__SPECS:-'unknown'}
    shift # past argument=value
    ;;
    -c=*|--comments=*)
    __COMMENTS="${i#*=}"
    COMMENTS=${__COMMENTS:-'none'}
    shift # past argument=value
    ;;
    --mapred.reduce.tasks=*)
    __mapred.reduce.tasks="${i#*=}"
    mapred.reduce.tasks=${__mapred.reduce.tasks:-92}
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done

echo "Launching terasort.sh to generate $SIZE data on $SPECS . Additional details : $COMMENTS"

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

RESULTSFILE="./$LOGDIR/terasort_results_$DATE"


INPUT=/data/sandbox/poc/teragen/${SIZE}-terasort-input
OUTPUT=/data/sandbox/poc/teragen/${SIZE}-terasort-output

# terasort.sh
# Kill any running MapReduce jobs
mapred job -list | grep job_ | awk ' { system("mapred job -kill " $1) } '
# Delete the output directory
hadoop fs -rm -r -f -skipTrash ${OUTPUT}

# Run terasort
time hadoop jar $MR_EXAMPLES_JAR terasort \
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
-Dmapreduce.task.io.sort.factor=300 \
-Dmapreduce.task.io.sort.mb=384 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx768m \
-Dyarn.app.mapreduce.am.resource.mb=1024 \
-Dmapred.reduce.tasks=92 \
-Dmapreduce.terasort.output.replication=1 \
${INPUT} ${OUTPUT} >> $RESULTSFILE 2>&1


END=$(date +%s);
secs=$(($END - $START))
DURATION=$(printf '%dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))

echo "***METRICS101*** | terasort.sh | $(printf "%4s" $SIZE) | $(printf "%10s" $ROWS) | $DURATION | $(printf "%6s" $secs) | specs: $(printf '%-20s' "${SPECS}") | comments: $(printf "%-50s" "${COMMENTS}") " >> $RESULTSFILE 2>&1

