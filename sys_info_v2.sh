#!/bin/bash
##############################################################
# File Name:31.project-system-xj.sh
# Version:V1.0
# Author:oldboy lidao996
# Organization:www.oldboyedu.com
##############################################################

res_file=/server/scripts/shell/sys_xj_result.csv
res_file_gbk=/server/scripts/shell/sys_xj_result_gbk.csv
echo "指标,值" >$res_file

welcome() {
echo cowsay "欢迎使用老男孩教育Linux79-系统巡检脚本"
}

sys_basic() {
hostname=`hostname`
ips=`hostname -I`
cat <<EOF
主机名,$hostname
ip地址,$ips
EOF
}

sys_mem_c7c8() {
mem_total=`free -m |awk  'NR==2{print $2"MB"}'`
mem_free=`free -m |awk  'NR==2{print $NF"MB"}'`
mem_free_percent=`free -m |awk  'NR==2{print $NF/$2*100"%"}'`
cat <<EOF
总计内存,$mem_total
可用内存,$mem_free
内存可用率,$mem_free_percent
EOF
}
sys_mem_c6() {
mem_total=`free -m |awk  'NR==2{print $2"MB"}'`
mem_free=`free -m |awk  'NR==3{print $NF"MB"}'`
mem_free_percent=`free -m |awk 'NR==2{total=$2}  NR==3{print   $NF/total*100"%"}'`
cat <<EOF
总计内存,$mem_total
可用内存,$mem_free
内存可用率,$mem_free_percent
EOF
}


sys_mem() {
 if [ -f /etc/os-release ];then
   sys_mem_c7c8
else
   sys_mem_c6
fi

}

sys_disk() {
fs_list="`awk '$3~/xfs|ext[2-4]|nfs/{print $2}'  /etc/fstab`"
for fs in $fs_list 
do 
   fs_size=`df -h $fs  |awk 'NR==2{print $2}'`
   fs_free=`df -h $fs  |awk 'NR==2{print $4}'`
   fs_used=`df -h $fs  |awk 'NR==2{print $3}'`
   fs_used_percent=`df -h $fs  |awk 'NR==2{print $5}'`
   cat <<-EOF
   磁盘分区$fs大小,$fs_size
   磁盘分区$fs剩余空间,$fs_free
   磁盘分区$fs已用空间,$fs_used
   磁盘分区$fs使用率,$fs_used_percent
	EOF
done
}
sys_cpu() {
cpu_cnt=`lscpu  |awk '/^Socket/{print $2}'`
cpu_core_total=`lscpu  |awk '/^CPU\(s\)/{print $2}'`
cpu_usage_user=`top  -b    -n1 |awk  -F "[ ,%]+"  'NR==3{print $2}'`
cpu_usage_sys=` top  -b    -n1 |awk  -F "[ ,%]+"  'NR==3{print $4}'`
cpu_usage_io=` top  -b    -n1 |awk  -F "[ ,%]+"  'NR==3{print $10}'`
cat <<EOF
CPU路数,$cpu_cnt
CPU核心总数,$cpu_core_total
用户占用cpu使用率,$cpu_usage_user
系统占用cpu使用率,$cpu_usage_sys
io占用cpu使用率,$cpu_usage_io
EOF
}

sys_load() {
sys_load_1=`uptime |awk -F'[ ,]+'  '{print $(NF-2)}'`
sys_load_5=`uptime |awk -F'[ ,]+'  '{print $(NF-1)}'`
sys_load_15=`uptime |awk -F'[ ,]+'  '{print $NF}'`
cat <<EOF
最近1分钟负载,$sys_load_1
最近5分钟负载,$sys_load_5
最近15分钟负载,$sys_load_15
EOF
}
sys_swap() {
swap_total=`free  |awk '/^Swap:/{print $2}'`
[ $swap_total -eq 0 ] && {
echo "是否有swap,否"
return 
} 
swap_free=`free  |awk '/^Swap:/{print $4}'`
swap_used=`free  |awk '/^Swap:/{print $3}'`
swap_free_percent=`free  |awk '/^Swap:/{print $4/$2*100"%"}'`
cat <<EOF
是否有swap,是
swap大小,$swap_total
swap剩余,$swap_free
swap使用,$swap_used
swap剩余率,$swap_free_percent
EOF
}

sys_sudo_user() {
sudo_user_01=`grep  '^[a-Z].*ALL=' /etc/sudoers |grep -v root`
sudo_user_wheel=`awk -F:  '/^wheel/{print $NF}' /etc/group`
cat <<EOF
系统拥有sudo权限的用户列表,$sudo_user_01 $sudo_user_wheel
EOF
}
sys_login_user() {
login_user_list="`awk   -F:  '/bash$/ && !/^#/{print $1}' /etc/passwd|xargs`"
login_user_recent="`lastlog  |grep -v "Never logged in" |awk 'NR>1{print $1}'|xargs`"
cat <<EOF
系统可登录用户列表,$login_user_list
登录过系统用户列表,$login_user_recent
EOF
}
sys_dns() {
sys_dns_list="`awk '/nameserver/{print $2}'  /etc/resolv.conf |xargs`"
host   baidu.com &>/dev/null
if [ $? -eq 0 ];then
   sys_dns_status=ok
else
   sys_dns_status=failed
fi
cat <<EOF
系统使用DNS服务器列表,$sys_dns_list
系统DNS服务器是否可用,$sys_dns_status

EOF
}

sys_ntp() {
ntp_srv=`ps -ef |grep ntp |egrep -v "grep|$0"|wc -l`
cron_ntp=`grep -c ntpdate   /var/spool/cron/root`
if [ $ntp_srv -eq 1   -o   $cron_ntp -eq 1 ];then
   sys_ntp_status=ok
else 
   sys_ntp_status=failed
fi 
cat <<EOF
系统是否有时间同步,$sys_ntp_status
EOF
}

#判断yum与yum仓库是否可通
sys_yum_repo() {
echo "curl/wget yum源的url 
yum源里面的baseurl 
curl -s  http://mirrors.aliyun.com/centos/7/extras/x86_64/ |grep  repodata
"
}

sys_proc() {
sys_normal_proc_list=/server/scripts/shell/process_list.txt
sys_now_proc_list=/server/scripts/shell/process_list_now.txt
ps -eo cmd  --noheading  |grep -v '\[.*\]' |grep    -v "\-bash" |grep -v "sshd:" |egrep -v "grep|$0" >$sys_now_proc_list
cat <<EOF
系统新增加的进程,`diff $sys_normal_proc_list $sys_now_proc_list|awk '/>/{print $2}' |uniq |xargs`
EOF
}

sys_service_c7c8() {
sys_startup_systemctl=`systemctl list-unit-files  |grep enabled |awk '{print $1}' |xargs`
sys_startup_local=`awk '!/^#|^$/{print $1}' /etc/rc.local  |sort |uniq   |xargs`
cat <<EOF
系统开机自启动服务,$sys_startup_systemctl
系统开机自启动服务,$sys_startup_local
EOF

}
sys_service_c6() {
sys_startup_systemctl=`chkconfig |grep 3:on|awk '{print $1}' |xargs`
sys_startup_local=`awk '!/^#|^$/{print $1}' /etc/rc.local  |sort |uniq   |xargs`
cat <<EOF
系统开机自启动服务,$sys_startup_systemctl
系统开机自启动服务,$sys_startup_local
EOF

}

sys_service() {
if [ -f /etc/os-release ];then
   sys_service_c7c8
else
   sys_service_c6
fi


}



main() {
sys_basic
sys_mem
sys_disk
sys_cpu
sys_load
sys_swap
sys_sudo_user
sys_login_user
sys_dns
sys_ntp
sys_proc
sys_service
}

welcome
main >>$res_file
iconv -f utf8   -t gbk   $res_file   -o   /server/scripts/shell/sys_xj_result_gbk.csv

