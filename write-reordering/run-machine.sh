### 
# @Descripttion: 
 # @version: 0.1
 # @Author: lwg
 # @Date: 2019-12-04 09:57:05
 # @LastEditors: lwg
 # @LastEditTime: 2019-12-11 16:57:59
 ###
#!/usr/bin/env bash
source $(dirname $0)/../scripts/utils.sh
source $(dirname $0)/../scripts/mlx_env.sh
#export HRD_REGISTRY_IP="akalianode-1.rdma.fawn.apt.emulab.net"
export HRD_REGISTRY_IP="192.168.3.112"

drop_shm
exe="../build/write-reordering"
chmod +x $exe

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

# Check for non-gdb mode
if [ "$#" -eq 1 ]; then
  sudo -E numactl --cpunodebind=0 --membind=0 $exe --is_client 1
fi

# Check for gdb mode
if [ "$#" -eq 2 ]; then
  sudo -E gdb -ex run --args $exe --is_client 1
fi
