### 
# @Descripttion: 
 # @version: 0.1
 # @Author: lwg
 # @Date: 2019-12-04 09:57:04
 # @LastEditors: lwg
 # @LastEditTime: 2019-12-10 16:00:05
 ###
# A function to echo in blue color
function blue() {
	es=`tput setaf 4`
	ee=`tput sgr0`
	echo "${es}$1${ee}"
}

export HRD_REGISTRY_IP="192.168.3.112"
export MLX5_SINGLE_THREADED=1
export MLX4_SINGLE_THREADED=1

if [ "$#" -ne 1 ]; then
    blue "Illegal number of parameters"
	blue "Usage: ./run-machine.sh <machine_number>"
	exit
fi

blue "Removing hugepages"
shm-rm.sh 1>/dev/null 2>/dev/null

sudo pkill memcached
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
sleep 1

num_threads=15		# Threads per client machine


blue "Running $num_threads client threads"

sudo LD_LIBRARY_PATH=/usr/local/lib/ -E \
	numactl --cpunodebind=0 --membind=0 ./main \
	--num-threads $num_threads \
	--base-port-index 0 \
	--num-server-ports 1 \
	--num-client-ports 1 \
	--is-client 1 \
	--update-percentage 0 \
	--machine-id $1 &
