#!/bin/bash
# Usage : teragen.sh --size=<1G|10G|100G|500G|1TB> --specs='3x R4XL(7-vcpu,32GB-RAM,250GB-EBS)' --comments='initial run'>

trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

#MR_EXAMPLES_JAR=/usr/hdp/2.2.0.0-2041/hadoop-mapreduce/hadoop-mapreduce-examples.jar
MR_EXAMPLES_JAR=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar

START=$(date +%s);
BASEDIR=$(dirname "$0")

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
    -l=*|--logdir=*)
    __LOGDIR="${i#*=}"
    LOGDIR=${__LOGDIR:-'${BASEDIR}/logs'}
    shift # past argument=value
    ;;
    --mapred.map.tasks=*)
    __mapred.map.tasks="${i#*=}"
    mapred.map.tasks=${__mapred.map.tasks:-92}
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

## Print the command to the log file before executing
exe () {
  params="$@"                       # Put all of the command-line into "params"
  printf "%s\t$params" "$(date)" >> "$LOGDIR" 2>&1  # Print the command to the log file
  $params                           # Execute the command
}

echo "Launching teragen.sh to generate $SIZE data on $SPECS . Additional details : $COMMENTS"

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
exe time hadoop jar $MR_EXAMPLES_JAR teragen \
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
-Dmapred.map.tasks=$mapred.map.tasks \
${ROWS} ${OUTPUT} >> $RESULTSFILE 2>&1
 
#-Dmapreduce.map.log.level=TRACE \
#-Dmapreduce.reduce.log.level=TRACE \
#-Dyarn.app.mapreqduce.am.log.level=TRACE \


END=$(date +%s);
secs=$(($END - $START))
DURATION=$(printf '%dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))

echo "***METRICS101*** |  teragen.sh | $(printf "%4s" $SIZE) | $(printf "%10s" $ROWS) | $DURATION | $(printf "%6s" $secs) | specs: $(printf '%-20s' "${SPECS}") | comments: $(printf "%-50s" "${COMMENTS}") " >> $RESULTSFILE 2>&1

