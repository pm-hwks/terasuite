# terasuite
teragen / terasort / testdfsio

# Usage :
Use these programs to test & validate terasort / hadoop disk io (testdfsio).

# Teragen & Terasort :
# Run multiple teragen & terasort with different parameters so it makes it possible to identify which settings work better for this instance

./teragen.sh  --size=100G --mapred_map_tasks=368 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=368' && \ 
./terasort.sh --size=100G --mapred_map_tasks=368 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=368' && \

./teragen.sh  --size=100G --mapred_map_tasks=184 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=184' && \ 
./terasort.sh --size=100G --mapred_map_tasks=184 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=184' && \

./teragen.sh  --size=100G --mapred_map_tasks=92 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=92' && \ 
./terasort.sh --size=100G --mapred_map_tasks=92 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=92' && \

./teragen.sh  --size=100G --mapred_map_tasks=46 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=46' && \ 
./terasort.sh --size=100G --mapred_map_tasks=46 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=46' && \

./teragen.sh  --size=100G --mapred_map_tasks=23 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=23' && \ 
./terasort.sh --size=100G --mapred_map_tasks=23 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=23' && \

./teragen.sh  --size=100G --mapred_map_tasks=10 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=10' && \ 
./terasort.sh --size=100G --mapred_map_tasks=10 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=10' && \ 

./teragen.sh  --size=100G --mapred_map_tasks=5 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=5' && \ 
./terasort.sh --size=100G --mapred_map_tasks=5 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='mapred_map_tasks=5' \


# DFS IO
# Use this to measure read/write performance of disks
./testdfsio-write.sh --size=10 --nooffiles=1000 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='test'
./testdfsio-read.sh  --size=10 --nooffiles=1000 -sp='4xR4XL (7-vcpu,32GB-RAM,500GB-EBS)' -c='test'



