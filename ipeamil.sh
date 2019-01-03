#!/bin/sh
cur_dir=$(cd "$(dirname "$0")"; pwd)
is_ipTXTexist=0
#####Update 2018.10.8;11.11.23;China Time;
echo "目前此脚本在您机器的绝对路径为 $cur_dir "
cd $cur_dir
echo "正在检查文件完整"
if [ -e 1.log ] ;then
        echo "发现1.log"
else
        touch 1.log
        echo "1.log不存在，已为您创建"
fi
if [ -e ip.txt ] ;then
        is_ipTXTexist=1
        echo "发现ip.txt"
else
        touch ip.txt
        echo "ip.txt不存在，已为您创建"
fi
if [ -e email.txt ] ;then
        echo "发现email.txt"
else
        touch email.txt
        echo "您的newifi历史IP变化如下：<br>" >> email.txt
        echo "email.txt不存在，已为您创建并填好预备内容"
fi
echo "文件完整检查工作完毕"
OLDIP=`cat $cur_dir/ip.txt`
FAYOUJIAN=0
NUM1=1
NUM0=0
IPADDRESS=$(/sbin/ifconfig ppp0 | sed -n 's/.*inet addr:\([^ ]*\).*/\1/p')
WANSTATE=$(mtk_esw 11 | sed -n 's/.*state: \([^ ]*\)/\1/p')
if [ $WANSTATE ==  $NUM1 ]
then
        if [ "$IPADDRESS" == "$OLDIP" ]   
        then                          
                echo "`date -u` not changed"
        else
                if [ "$IPADDRESS" ==  "" ]
                then
                        TIMETMP=$(date)
                        sleep 1.5m
                        IPADDRESS=$(/sbin/ifconfig ppp0 | sed -n 's/.*inet addr:\([^ ]*\).*/\1/p')
                        if [ "$IPADDRESS" ==  "" ]
                        then
                                echo "$TIMETMP##获取IP失败，路由器掉线<br>" >> $cur_dir/email.txt
                        else
                                echo "$TIMETMP<br>##重新拨号并成功获取IP:$IPADDRESS<br>" >> $cur_dir/email.txt
                                FAYOUJIAN=1
                        fi
                else
                        echo "`date -u` changed" >> $cur_dir/1.log
                        if [ "$OLDIP" == "" -o $is_ipTXTexist == $NUM0 ]
                        then
                                TIMETMP=$(date)
                                OLDIP="（空）"
                                echo "$TIMETMP<br>##首次拨号成功并获得IP:$IPADDRESS<br>" >> $cur_dir/email.txt
                        else
                                echo "$OLDIP=>$IPADDRESS<br>" >> $cur_dir/email.txt
                        fi
                        FAYOUJIAN=1
                fi
        fi
else
        if [ $is_ipTXTexist == $NUM1 ]
        then
                echo "`date` 路由器网线断线<br>" >> $cur_dir/email.txt
        fi
        rm -f $cur_dir/ip.txt
fi
echo $IPADDRESS > $cur_dir/ip.txt
if [ $FAYOUJIAN ==  $NUM1 ]
then
        HISTORYIP=`cat $cur_dir/email.txt`
        fromAdd="xxx@126.com"
        tolist="xxx@126.com"
        subject="IP Changed"
        (
        echo "From: $fromAdd"
        echo "To: $tolist"
        echo "Subject: $subject"
        echo "MIME-Version: 1.0"
        echo 'Content-Type: multipart/mixed; boundary="GvXjxJ+pjyke8COw"'
        #echo "Content-Disposition: inline"
        echo
        echo "--GvXjxJ+pjyke8COw"
        echo "Content-Type: text/html; charset=utf-8"
        echo "Content-Disposition: inline"
        echo
        echo "现在IP为<font color="hotpink">$IPADDRESS</font><br>"
        echo "啦啦啦我是华丽的文字分割线啦啦啦<br>"
        echo
        echo "<br> $HISTORYIP <br>"
        echo "<br>上次IP为<font color="orange">$OLDIP </font><br><br><br>"
        echo
        echo "现在IP为<font color="hotpink">$IPADDRESS</font> <br>"
        echo "--GvXjxJ+pjyke8COw"
        ) | sendmail -f $fromAdd -t $tolist  -S smtp.126.com -au"username" -ap"password"
        logger "已执行完发送邮件命令！"
fi
logger "ipemail.sh脚本执行完毕！"
