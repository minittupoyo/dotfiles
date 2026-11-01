#!/bin/sh
# システムの状態を key=value で出力する (quickshell の services/SystemStats が定期的に読む)。
#   cpu=<user nice system idle iowait irq softirq steal>   /proc/stat の累積値
#   mem_total_kb / mem_avail_kb
#   cpu_temp=<℃> / nvme=<℃> (複数行)
#   gpu=<使用率%>,<温度℃>,<VRAM 使用 MiB>,<VRAM 合計 MiB>,<消費電力 W>,<電力上限 W>   (NVIDIA)

head -1 /proc/stat | sed 's/^cpu *//; s/^/cpu=/'
awk '/^MemTotal:/{print "mem_total_kb=" $2} /^MemAvailable:/{print "mem_avail_kb=" $2}' /proc/meminfo

for h in /sys/class/hwmon/hwmon*; do
    [ -r "$h/temp1_input" ] || continue
    case "$(cat "$h/name" 2>/dev/null)" in
        k10temp|coretemp) awk '{printf "cpu_temp=%.1f\n", $1 / 1000}' "$h/temp1_input" ;;
        nvme) awk '{printf "nvme=%.0f\n", $1 / 1000}' "$h/temp1_input" ;;
    esac
done

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit \
        --format=csv,noheader,nounits 2>/dev/null | sed 's/ //g; s/^/gpu=/'
fi
