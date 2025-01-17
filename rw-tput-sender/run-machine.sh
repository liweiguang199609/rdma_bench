### 
# @Descripttion: 
 # @version: 0.1
 # @Author: lwg
 # @Date: 2019-12-04 09:57:05
 # @LastEditors: lwg
 # @LastEditTime: 2019-12-11 20:28:29
 ###
#!/usr/bin/env bash
source $(dirname $0)/../scripts/utils.sh
source $(dirname $0)/../scripts/mlx_env.sh
export HRD_REGISTRY_IP="192.168.3.112"

drop_shm

# lsync messes up permissions
executable="../build/rw-tput-sender"
chmod +x $executable

num_threads=16			# Threads per client machine
blue "Running $num_threads client threads"

# Check number of arguments
if [ "$#" -gt 2 ]; then
  blue "Illegal number of arguments."
  blue "Usage: ./run-machine.sh <machine_id>, or ./run-machine.sh <machine_id> gdb"
	exit
fi

if [ "$#" -eq 0 ]; then
  blue "Illegal number of arguments."
  blue "Usage: ./run-machine.sh <machine_id>, or ./run-machine.sh <machine_id> gdb"
	exit
fi

flags="\
  --num_threads $num_threads \
	--dual_port 0 \
	--use_uc 0 \
	--is_client 1 \
	--machine_id $1
"

# Check for non-gdb mode
if [ "$#" -eq 1 ]; then
  sudo -E numactl --cpunodebind=0 --membind=0 $executable $flags
fi

# Check for gdb mode
if [ "$#" -eq 2 ]; then
  sudo -E gdb -ex run --args $executable $flags
fi
