#!/bin/bash

kw="$1"
ti="$2"

# 从top命令中获取关键词相关的所有进程
function get_p() {
  kw=$*
  top -n 1 -b | grep "$kw" | sed 's/\s\+/ /g' | sed 's/^\s//g'
}

# 从top命令中获取总的CPU占用比例
function get_all_cpu() {
  top -n 1 -b | grep "%Cpu(s):" | cut -d "," -f 1 | sed 's/\s\+//g' | sed -e 's/%Cpu(s):\(.*\)us/\1/'
}

# 从free命令中获取总的内存占用比例
function get_all_mem() {
  free | grep "Mem:" | awk '{print ($2-$7)/$2*100}'
}

# 从iostat命令中获取挂载/mnt/ONCOBOX路径的磁盘总的IO占用比例
function get_box_io() {
  dev=$(df -h | grep "ONCOBOX" | cut -d " " -f 1 | cut -d "/" -f 3 | cut -c 1-3)
  iostat -d -m -x | grep "$dev" | sed 's/\s\+/ /g' | cut -d " " -f 14
}

function get_p_cpu() {
  p=$*
  echo "$p" | cut -d " " -f 9 | awk '{sum+=$1} END {print sum}'
}

function get_p_mem() {
  p=$*
  echo "$p" | cut -d " " -f 10 | awk '{sum+=$1} END {print sum}'
}

function get_p_pid() {
  p=$*
  echo "$p" | cut -d " " -f 1 | tr "\n" ";" | sed 's/;$/\n/'
}

function get_p_cm() {
  p=$*
  time=$(date "+%Y-%m-%d %H:%M:%S")
  all_cpu=$(get_all_cpu)
  all_mem=$(get_all_mem)
  box_io=$(get_box_io)
  p_cpu=$(get_p_cpu "$p")
  p_mem=$(get_p_mem "$p")
  p_pid=$(get_p_pid "$p")
  p_pid_n=$(echo "$p" | wc -l)
  echo -e "$time\t$all_cpu\t$all_mem\t$box_io\t$p_cpu\t$p_mem\t$p_pid\t$p_pid_n"
}

start_time=$(date +%s)
fn=${start_time}_monitor.txt

while true; do
  p=$(get_p "$kw")

  if [ -n "$p" ]; then
    if [ -f "$fn" ]; then
      p_cm=$(get_p_cm "$p")
      echo "$p_cm" >>"$fn"
      sleep "$ti"
    else
      echo -e "Time\tAll_CPU(%)\tAll_Mem(%)\tBox_IO(%)\tP_CPU(%)\tP_Mem(%)\tPid\tPid_Num"
    fi

  else
    echo "警告：没有找到关键词-- $kw 相关进程！"
    break
  fi
done

if [ -f "$fn" ]; then
  sed -i '1i\Time\tAll_CPU(%)\tAll_Mem(%)\tBox_IO(%)\tP_CPU(%)\tP_Mem(%)\tPid\tPid_Num' "$fn"
fi

end_time=$(date +%s)
used_time=$(($end_time - $start_time))
echo "监控耗时 $used_time 秒"
