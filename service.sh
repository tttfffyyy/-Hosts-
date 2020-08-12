#!/system/bin/sh
# 不用猜测您的模块将安装在哪
# 如果您需要知道此脚本的位置，请始终使用$MODDIR设置模块
# 如果Magisk将来更改其安装点
# 这将确保您的模块仍能正常工作
MODDIR=${0%/*}

# 该脚本将在late_start服务模式下执行
sleep 25
description=$MODDIR/module.prop
NewVersionA=`curl --connect-timeout 10 -m 10 -s 'https://raw.githubusercontent.com/Coolapk-Code9527/-Hosts-/master/README.md' | grep 'version=' | cut -d '=' -f 2`
NewVersionB=`echo $NewVersionA | sed 's/[^0-9]//g'`
NewVersionC=`curl --connect-timeout 10 -m 10 -s 'https://gitee.com/coolapk-code_9527/border/raw/master/README.md' | grep 'version=' | cut -d '=' -f 2`
NewVersionD=`echo $NewVersionC | sed 's/[^0-9]//g'`
NewVersionE=`wget -q -T 10 -O- --no-check-certificate 'https://raw.githubusercontent.com/Coolapk-Code9527/-Hosts-/master/README.md' | grep 'version=' | cut -d '=' -f 2`
NewVersionF=`echo $NewVersionE | sed 's/[^0-9]//g'`
NewVersionG=`wget -q -T 10 -O- --no-check-certificate 'https://gitee.com/coolapk-code_9527/border/raw/master/README.md' | grep 'version=' | cut -d '=' -f 2`
NewVersionH=`echo $NewVersionG | sed 's/[^0-9]//g'`
Version=`cat $MODDIR/module.prop | grep 'version=' | sed 's/[^0-9]//g'`
usage=`du $MODDIR/system/etc/hosts | awk '{print $1}'`
sysusage=`du /system/etc/hosts | awk '{print $1}'`
if [[ "$usage" -ne "$sysusage" ]];then
sed -i "s/description\=/description\=『hosts未生效❌』/g;s/description\=.*』/description\=『hosts未生效❌』/g" $description
elif [[ "$?" -ne 0 ]];then
sed -i "s/description\=.*』/description\=/g" $description
fi
if [[ "$NewVersionB" != "" && "$NewVersionB" -gt "$Version" ]];then
sed -i "s/！/！（检测到有新版本\[️GitHub🆕"$NewVersionA"\]❗）/g;s/！.*）/！（检测到有新版本\[️GitHub🆕"$NewVersionA"\]❗）/g" $description
elif [[ "$NewVersionD" != "" && "$NewVersionD" -gt "$Version" ]];then
sed -i "s/！/！（检测到有新版本\[️Gitee🆕"$NewVersionC"\]❗）/g;s/！.*）/！（检测到有新版本\[️Gitee🆕"$NewVersionC"\]❗）/g" $description
elif [[ "$NewVersionF" != "" && "$NewVersionF" -gt "$Version" ]];then
sed -i "s/！/！（检测到有新版本\[️GitHub🆕"$NewVersionE"\]❗）/g;s/！.*）/！（检测到有新版本\[️GitHub🆕"$NewVersionE"\]❗）/g" $description
elif [[ "$NewVersionH" != "" && "$NewVersionH" -gt "$Version" ]];then
sed -i "s/！/！（检测到有新版本\[️Gitee🆕"$NewVersionG"\]❗）/g;s/！.*）/！（检测到有新版本\[️Gitee🆕"$NewVersionG"\]❗）/g" $description
elif [[ "$?" -ne 0 ]];then
sed -i "s/！.*）/！/g" $description
fi

while true; do
ipv4dns=`cat $MODDIR/ipv4dns.prop | awk '!/#/ {print $NF}' | cut -d "=" -f 2`
ipv6dns=`cat $MODDIR/ipv6dns.prop | awk '!/#/ {print $NF}' | cut -d "=" -f 2`
ipv4dnsovertls=`cat $MODDIR/ipv4dnsovertls.prop | awk '!/#/ {print $NF}' | cut -d "=" -f 2`
ipv6dnsovertls=`cat $MODDIR/ipv6dnsovertls.prop | awk '!/#/ {print $NF}' | cut -d "=" -f 2`
AndroidSDK=`getprop ro.build.version.sdk`
dotmode=`settings get global private_dns_mode`
dotspecifier=`settings get global private_dns_specifier`

if [[ -s $MODDIR/ipv4dns.prop ]];then
for dns in $ipv4dns; do
    setsid ping -c 100 -w 10 -A -q $dns >> $MODDIR/ipv4dns.log
    sleep 0.2
done
fi

avg=`cat $MODDIR/ipv4dns.log | grep 'min/avg/max' | cut -d "=" -f 2 | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
ewma=`cat $MODDIR/ipv4dns.log | grep -w 'ipg/ewma' | sed 's/.*ipg\/ewma//g' | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
avgtest=`echo $avg | awk -F"/" '{printf("%.f\n",$2)}' `
ewmatest=`echo $ewma | awk -F"/" '{printf("%.f\n",$2)}' `
dnsavg=`cat $MODDIR/ipv4dns.log | grep -B 2 "$avg" | awk 'NR==1{print $2}' `
dnsewma=`cat $MODDIR/ipv4dns.log | grep -B 2 "$ewma" | awk 'NR==1{print $2}' `

if [[ "$dnsavg" != "" && "$avgtest" -lt 150 ]];then
    iptables -t nat -F OUTPUT
    iptables -t nat -F POSTROUTING
    iptables -t nat -A OUTPUT -p tcp --dport 5353 -j REDIRECT --to-ports 53
    iptables -t nat -A OUTPUT -p udp --dport 5353 -j REDIRECT --to-ports 53
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $dnsavg:53
    iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $dnsavg:53
    iptables -t nat -A POSTROUTING -j MASQUERADE
elif [[ "$dnsewma" != "" && "$ewmatest" -lt 150 ]];then
    iptables -t nat -F OUTPUT
    iptables -t nat -F POSTROUTING
    iptables -t nat -A OUTPUT -p tcp --dport 5353 -j REDIRECT --to-ports 53
    iptables -t nat -A OUTPUT -p udp --dport 5353 -j REDIRECT --to-ports 53
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $dnsewma:53
    iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $dnsewma:53
    iptables -t nat -A POSTROUTING -j MASQUERADE
else
    iptables -t nat -F OUTPUT
    iptables -t nat -F POSTROUTING
fi

    ip6tables -t nat -nL >/dev/null 2>&1
if [[ "$?" -eq 0 && -s $MODDIR/ipv6dns.prop ]];then
for dnss in $ipv6dns; do
    setsid ping6 -c 100 -A -w 10 -q $dnss >> $MODDIR/ipv6dns.log
    sleep 0.2
done
fi

ipv6avg=`cat $MODDIR/ipv6dns.log | grep 'min/avg/max' | cut -d "=" -f 2 | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
ipv6ewma=`cat $MODDIR/ipv6dns.log | grep -w 'ipg/ewma' | sed 's/.*ipg\/ewma//g' | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
ipv6avgtest=`echo $ipv6avg | awk -F"/" '{printf("%.f\n",$2)}' `
ipv6ewmatest=`echo $ipv6ewma | awk -F"/" '{printf("%.f\n",$2)}' `
ipv6dnsavg=`cat $MODDIR/ipv6dns.log | grep -B 2 "$ipv6avg" | awk 'NR==1{print $2}' `
ipv6dnsewma=`cat $MODDIR/ipv6dns.log | grep -B 2 "$ipv6ewma" | awk 'NR==1{print $2}' `

if [[ "$ipv6dnsavg" != "" && "$ipv6avgtest" -lt 150 ]];then
    ip6tables -t nat -F OUTPUT
    ip6tables -t nat -F POSTROUTING
    ip6tables -t nat -A OUTPUT -p tcp --dport 5353 -j REDIRECT --to-ports 53
    ip6tables -t nat -A OUTPUT -p udp --dport 5353 -j REDIRECT --to-ports 53
    ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $ipv6dnsavg:53
    ip6tables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $ipv6dnsavg:53
    ip6tables -t nat -A POSTROUTING -j MASQUERADE
elif [[ "$ipv6dnsewma" != "" && "$ipv6ewmatest" -lt 150 ]];then
    ip6tables -t nat -F OUTPUT
    ip6tables -t nat -F POSTROUTING
    ip6tables -t nat -A OUTPUT -p tcp --dport 5353 -j REDIRECT --to-ports 53
    ip6tables -t nat -A OUTPUT -p udp --dport 5353 -j REDIRECT --to-ports 53
    ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $ipv6dnsewma:53
    ip6tables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $ipv6dnsewma:53
    ip6tables -t nat -A POSTROUTING -j MASQUERADE
else
    ip6tables -t nat -F OUTPUT
    ip6tables -t nat -F POSTROUTING
fi

if [[ "$AndroidSDK" -ge "28" && "$dotmode" != "" && -s $MODDIR/ipv4dnsovertls.prop ]];then
for dot in $ipv4dnsovertls; do
    setsid ping -c 100 -A -w 10 -q $dot >> $MODDIR/ipv4dnsovertls.log
    sleep 0.2
done
fi

if [[ "$AndroidSDK" -ge "28" && "$dotmode" != "" && -s $MODDIR/ipv6dnsovertls.prop ]];then
for dots in $ipv6dnsovertls; do
    setsid ping -c 100 -A -w 10 -q $dots >> $MODDIR/ipv6dnsovertls.log
    sleep 0.2
done
fi

dotavg=`cat $MODDIR/ipv4dnsovertls.log | grep 'min/avg/max' | cut -d "=" -f 2 | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
dotewma=`cat $MODDIR/ipv4dnsovertls.log | grep -w 'ipg/ewma' | sed 's/.*ipg\/ewma//g' | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
dotavgtest=`echo $dotavg | awk -F"/" '{printf("%.f\n",$2)}' `
dotewmatest=`echo $dotewma | awk -F"/" '{printf("%.f\n",$2)}' `
dotdnsavg=`cat $MODDIR/ipv4dnsovertls.log | grep -B 2 "$dotavg" | awk 'NR==1{print $2}' `
dotdnsewma=`cat $MODDIR/ipv4dnsovertls.log | grep -B 2 "$dotewma" | awk 'NR==1{print $2}' `
ipv6dotavg=`cat $MODDIR/ipv6dnsovertls.log | grep 'min/avg/max' | cut -d "=" -f 2 | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
ipv6dotewma=`cat $MODDIR/ipv6dnsovertls.log | grep -w 'ipg/ewma' | sed 's/.*ipg\/ewma//g' | sort -t '/' -k 2n | awk 'NR==1{print $1}' `
ipv6dotavgtest=`echo $ipv6dotavg | awk -F"/" '{printf("%.f\n",$2)}' `
ipv6dotewmatest=`echo $ipv6dotewma | awk -F"/" '{printf("%.f\n",$2)}' `
ipv6dotdnsavg=`cat $MODDIR/ipv6dnsovertls.log | grep -B 2 "$ipv6dotavg" | awk 'NR==1{print $2}' `
ipv6dotdnsewma=`cat $MODDIR/ipv6dnsovertls.log | grep -B 2 "$ipv6dotewma" | awk 'NR==1{print $2}' `

if [[ "$ipv6dotdnsavg" != "" && "$dotavgtest" -gt "$ipv6dotavgtest" && "$ipv6dotavgtest" -lt 150 ]];then
    settings put global private_dns_specifier $ipv6dotdnsavg
elif [[ "$dotdnsavg" != "" && "$dotavgtest" -lt 150 ]];then
    settings put global private_dns_specifier $dotdnsavg
elif [[ "$ipv6dotdnsewma" != "" && "$dotewmatest" -gt "$ipv6dotewmatest" && "$ipv6dotewmatest" -lt 150 ]];then
    settings put global private_dns_specifier $ipv6dotdnsewma
elif [[ "$dotdnsewma" != "" && "$dotewmatest" -lt 150 ]];then
    settings put global private_dns_specifier $dotdnsewma
fi

description=$MODDIR/module.prop
iptdnsTesting=`iptables -t nat -nL OUTPUT --line-numbers | grep 'dpt:53 ' | awk 'NR==1{print $(NF)}' | cut -d ':' -f 2- | cut -d ':' -f 1`
ipt6dnsTesting=`ip6tables -t nat -nL OUTPUT --line-numbers | grep 'dpt:53 ' | awk 'NR==1{print $(NF)}' | cut -d ':' -f 2- | sed 's/\:53//g'`
ipv4Testingname=`cat $MODDIR/ipv4dns.prop | grep "$iptdnsTesting" | cut -d "=" -f 1`
ipv6Testingname=`cat $MODDIR/ipv6dns.prop | grep "$ipt6dnsTesting" | cut -d "=" -f 1`
dotTestingname=`cat $MODDIR/ipv4dnsovertls.prop | grep "$dotspecifier" | cut -d "=" -f 1`
ipv6dotTestingname=`cat $MODDIR/ipv6dnsovertls.prop | grep "$dotspecifier" | cut -d "=" -f 1`
refreshtime=`date +"%Y-%m-%d %H:%M:%S"`

if [[ "$ipv4Testingname" != "" && "$ipv6Testingname" != "" && "$ipv6dotTestingname" != "" ]];then
sed -i "s/- .*/- IPV4：\["$ipv4Testingname"："$iptdnsTesting"\] - IPV6：\["$ipv6Testingname"："$ipt6dnsTesting"\] - 私人DNS：\["$ipv6dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv4Testingname" != "" && "$ipv6Testingname" != "" && "$dotTestingname" != "" ]];then
sed -i "s/- .*/- IPV4：\["$ipv4Testingname"："$iptdnsTesting"\] - IPV6：\["$ipv6Testingname"："$ipt6dnsTesting"\] - 私人DNS：\["$dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv4Testingname" != "" && "$ipv6dotTestingname" != "" ]];then
sed -i "s/- .*/- IPV4：\["$ipv4Testingname"："$iptdnsTesting"\] - 私人DNS：\["$ipv6dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv4Testingname" != "" && "$dotTestingname" != "" ]];then
sed -i "s/- .*/- IPV4：\["$ipv4Testingname"："$iptdnsTesting"\] - 私人DNS：\["$dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv4Testingname" != "" && "$ipv6Testingname" != "" ]];then
sed -i "s/- .*/- IPV4：\["$ipv4Testingname"："$iptdnsTesting"\] - IPV6：\["$ipv6Testingname"："$ipt6dnsTesting"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv6Testingname" != "" && "$ipv6dotTestingname" != "" ]];then
sed -i "s/- .*/- IPV6：\["$ipv6Testingname"："$ipt6dnsTesting"\] - 私人DNS：\["$ipv6dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv6Testingname" != "" && "$dotTestingname" != "" ]];then
sed -i "s/- .*/- IPV6：\["$ipv6Testingname"："$ipt6dnsTesting"\] - 私人DNS：\["$dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv4Testingname" != "" ]];then
sed -i "s/- .*/- IPV4：\["$ipv4Testingname"："$iptdnsTesting"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv6Testingname" != "" ]];then
sed -i "s/- .*/- IPV6：\["$ipv6Testingname"："$ipt6dnsTesting"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$ipv6dotTestingname" != "" ]];then
sed -i "s/- .*/- 私人DNS：\["$ipv6dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
elif [[ "$dotTestingname" != "" ]];then
sed -i "s/- .*/- 私人DNS：\["$dotTestingname"："$dotspecifier"\]   --- 刷新时间：\[""$refreshtime""\] /g" $description
else
sed -i "s/- .*/- /g" $description
fi

echo > $MODDIR/ipv4dns.log
echo > $MODDIR/ipv6dns.log
echo > $MODDIR/ipv4dnsovertls.log
echo > $MODDIR/ipv6dnsovertls.log
sleep 10
reset
done


