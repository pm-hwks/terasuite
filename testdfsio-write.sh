
#!/bin/bash
# Usage : testdfsio-write.sh --size=<10|100|1000|10000 (MB)> --nooffiles=10 --specs='3x R4XL(7-vcpu,32GB-RAM,250GB-EBS)' --comments='initial run'>

trap "" HUP

#if [ $EUID -eq 0 ]; then
#   echo "this script must not be run as root. su to hdfs user to run"
#   exit 1
#fi

MR_TEST_JAR=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-client-jobclient-tests.jar

START=$(date +%s);

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
DEFAULT_LOGDIR=${BASEDIR%%/}/logs

# Parsing the input arguements
for i in "$@"
do
case $i in
    -s=*|--size=*)
    __SIZE="${i#*=}"
    shift # past argument=value
    ;;
    -n=*|--nooffiles=*)
    __NOF="${i#*=}"
    shift # past argument=value
    ;;
    -sp=*|--spec=*)
    __SPECS="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--comments=*)
    __COMMENTS="${i#*=}"
    shift # past argument=value
    ;;
    -l=*|--logdir=*)
    __LOGDIR="${i#*=}"
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

# Setting default value
SIZE=${__SIZE:-100}
NOF=${__NOF:-10}
SPECS=${__SPECS:-'unknown'}
COMMENTS=${__COMMENTS:-'none'}
LOGDIR=${__LOGDIR:-"$DEFAULT_LOGDIR"}


if [ ! -d "$LOGDIR" ]
then
    mkdir $LOGDIR
fi

DATE=`date +%Y-%m-%d:%H:%M:%S`

RESULTSFILE="$LOGDIR/testdfsio-write_results_$DATE"
METRICSFILE="$LOGDIR/metrics.txt"


## Print the command to the log file before executing
exe () {
  params="$@"                       # Put all of the command-line into "params"
  printf "%s\t$params" "$(date)" >> "$RESULTSFILE" 2>&1  # Print the command to the log file
  $params                           # Execute the command
}

echo "Launching testdfsio-write.sh to generate $SIZE data on $SPECS . Additional details : $COMMENTS"

# Kill any running MapReduce jobs
mapred job -list | grep job_ | awk ' { system("mapred job -kill " $1) } '

# Run testdfsio-write
exe time hadoop jar $MR_TEST_JAR TestDFSIO  \
-D mapred.output.compress=false                 \
-write                                          \
-nrFiles $NOF                                   \
-fileSize $SIZE                                 \
>> $RESULTSFILE 2>&1
 

END=$(date +%s);
secs=$(($END - $START))
DURATION=$(printf '%dh:%dm:%ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)))

OP=$(echo "***METRICS101*** |  testdfsio-write.sh | $(printf "%8s" $SIZE) | $(printf "%4s" $NOF) | $DURATION | $(printf "%6s" $secs) | specs: $(printf '%-20s' "${SPECS}") | comments: $(printf "%-50s" "${COMMENTS}")") 

#write to log file
echo $OP >> $RESULTSFILE 2>&1

#write to metrics file
echo $OP >> $METRICSFILE 2>&1
