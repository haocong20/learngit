#!/bin/bash
##############################################################
# File Name:30.project.system-secure.sh
# Version:V1.0
# Author:oldboy lidao996
# Organization:www.oldboyedu.com
# desc 系统加固检查
##############################################################

. /etc/init.d/functions 

welcome() {
dialog --msgbox  老男孩Linux79期-系统加固检查脚本 30 50
}
auth_password_quality() {
cnt=`egrep -c 'difok=|minlen=|ucredit=|lcredit=|dcredit=' /etc/pam.d/system-auth`
if [ $cnt -eq 0 ];then
   action  "没有密码长度,大小写,数字,相关限制"  /bin/false
else
   action  "有密码长度,大小写,数字,相关限制"   /bin/true
fi
}

auth_password_fail() {
cnt=`egrep -c 'deny=|unlock_time=|lock_time=' /etc/pam.d/system-auth`
if [ $cnt -eq 0 ];then
   action  "没有登录失败次数的限制"  /bin/false
else
   action  "有登录失败次数的限制"  /bin/true
fi
}
auth_password_expire() {
expire_Day=90
conf_File_Expire_Day=`awk '/^PASS_MAX_DAYS/{print $2}' /etc/login.defs`

if [ $conf_File_Expire_Day -le  $expire_Day ];then
   action  "已经设置了密码过期时间: $conf_File_Expire_Day"  /bin/true
else
   action  "没有设置了密码过期时间: $conf_File_Expire_Day"  /bin/false
fi
}
auth_service_telnet() {
cnt=`ss -lntup |grep -c 'telnet'`
if [ $cnt -eq 0 ];then
   action  "telnet服务没有开启"  /bin/true
else
   action  "telnet服务已经开启"  /bin/false
fi
}

auth_password_history() {
cnt=`egrep -c 'remember=' /etc/pam.d/system-auth`
if [ $cnt -eq 0 ];then
   action  "没有限制使用历史密码"  /bin/false
else
   action  "限制使用历史密码"  /bin/true
fi
}

access_nologin_user() {
name_list="lp  nuucp  hpdb  sync  adm ftp  games "
for name in $name_list
do
    id  $name &>/dev/null   || continue 
   cnt=`passwd  -S   "$name"  |awk '{print $2}'`
   if [ "$cnt" = "LK" ];then
      action  "虚拟用户已经被锁定: $name"  /bin/true
   else
      action  "虚拟用户没有被锁定: $name"  /bin/false
   fi
done

}

access_fake_root() {
cnt=`awk  -F: '$3==0 &&  $1!="root"  {print $1}'  /etc/passwd |wc -l`
if [ $cnt -eq 0 ];then
   action  "没有uid是0的非root用户"  /bin/true
else
   action  "有uid是0的非root用户"  /bin/false
   awk  -F: '$3==0 &&  $1!="root"  {print $1}'  /etc/passwd
fi
}
access_umask_value() {
cnt=`umask`
if [ $cnt -eq 0027 ];then
   action  "umask是0027"  /bin/true
else
   action  "umask不是0027 $cnt"  /bin/false
fi
}

access_file_mode() {
vip_list=/server/scripts/shell/vip_file_dir.txt
while read   perm  name
do 
   [ -e $name ] || continue
   perm_new=`stat -c%a $name`
   if [ $perm_new -eq $perm ];then
      action  "权限没有变化: $name"  /bin/true
   else
      action  "权限有变化:   $name $perm --> $perm_new"  /bin/false
   fi
done <$vip_list

}
access_sgid_mode() {
file=/server/scripts/shell/sgid-suid.txt
file_cnt_old=`cat $file`
file_cnt_now=`find /  -perm  /+s 2>/dev/null |wc -l`
if [[ $file_cnt_old -eq $file_cnt_now ]]
    then
   action  "系统suid sgid文件没有发送变化"  /bin/true
else
   action  "系统suid sgid文件有发送变化"  /bin/false
fi

}

access_rwx_file() {
dir_list="`awk '$3~/xfs|ext[2-4]/{print $2}'  /etc/fstab`"
res_file=/server/scripts/shell/rwx.log
>$res_file
for dir  in $dir_list
do
   cnt=`find  / -xdev   \( -type d -o  -type f  \) -perm  /o+w  |wc -l`
   [ $cnt -eq 0 ] && continue 
   find  $dir -xdev   \( -type d -o  -type f  \) -perm  /o+w       >>$res_file
done
res_file_cnt=`cat $res_file|wc -l`
if [ $res_file_cnt -eq 0 ];then
   action  "系统中没有任何人都可以写的文件或目录"  /bin/true
else
   action  "系统中有任何人都可以写的文件或目录"  /bin/false
fi

}
access_homeless_file() {
dir_list="`awk '$3~/xfs|ext[2-4]/{print $2}'  /etc/fstab`"
res_file=/server/scripts/shell/homeless.log
>$res_file
for dir  in $dir_list
do
   cnt=`find $dir  -xdev  -nouser -o -nogroup   |wc -l`
   [ $cnt -eq 0 ] && continue 
   find $dir  -xdev  -nouser -o -nogroup       >>$res_file
done
res_file_cnt=`cat $res_file|wc -l`
if [ $res_file_cnt -eq 0 ];then
   action  "系统没有任何无家可归的文件或目录"  /bin/true
else
   action  "系统有任何无家可归的文件或目录 记录在$res_file中"  /bin/false
fi


}

access_hide_file() {
echo null
}

access_system_cad() {
if [ -l /usr/lib/systemd/system/ctrl-alt-del.target ];then
   action  "系统没有禁用ctrl+alt+delete重启功能"  /bin/false
else
   action  "系统禁用ctrl+alt+delete重启功能"  /bin/true
fi


}
control_ssh() {
cnt=`grep -i '^PermitRootLogin.*no'  /etc/ssh/sshd_config |wc -l`
if [ $cnt -eq 0 ];then
   action  "系统没用禁用root远程登录"  /bin/false
else
   action  "系统禁用root远程登录"  /bin/true
fi
}

auth_passwd() {
auth_password_quality
auth_password_fail
auth_password_expire
auth_service_telnet
auth_password_history
}

access_things() {
access_nologin_user
access_fake_root
access_umask_value
access_file_mode
access_sgid_mode
access_rwx_file
access_homeless_file
}

main() {
welcome
auth_passwd
access_things
control_ssh

}

main
