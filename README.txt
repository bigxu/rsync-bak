目前备份就是用的这个脚本

---------
bash shell 分析 ini 配置文件
rsync 自动备份文件
---------

初始化：

1, 设置crontab
2, 安装lzop

---------

# m h  dom mon dow   command
0 0 * * * (/usr/sbin/ntpdate 133.100.9.2) > /dev/null 2>&1
0 0 * * * /home/bigxu/workspace/setup-config/dmesg-check/check.sh > /dev/null 2>&1
0 1 * * * /home/bigxu/workspace/setup-config/bak-to-d5/bak.sh > /home/bigxu/tmp/bak.log 2>&1
#*/30 * * * *  /usr/local/bin/php /home/bigxu/workspace/setup-config/bak-rsync/monitor > /dev/null 2>&1

--------

注意事项: .ssh/config 文件区分认证证书类型，并备份了rsa文件，在该目录呢。

-------------
写这个备份脚本有三个目的
1, 干净完全的备份，不要丢东落西的
2, 最小牺牲生产机的性能
3, 简易的配置，希望是一劳永逸。只改写配置文件就行了。

-------------
执行远程脚本
ssh_command 远程服务器的脚本
如,ssh_command=/home/bigxu/workspace/setup-config/fragment/d6-bak-gitlab.sh
gitlab的官方备份/恢复有点麻烦，执行此命令会暂这一下gitlab docker，备份数据目录。然后同步到备份机上来。

-------------
mysql导出
mysql 导出在当前的dir中. 不必考虑删除昨天的，重名之类的事，已经完全处理了。
现在mysql导出极为方便了.
可以指定任何参数，当然也可以指定某个库了
mysql_dump_command=/usr/local/bin/mysqldump56 -uroot -ppassword --all-databases

-------------
同步目录
dir, 要同步的目录
bak_day, 备份保留多久
bak_freq, 隔几天备份一次
exclude=--exclude "mysql/data" --exclude "xx" 排除目录


; [xx 标题陈述 ]
; server,port,dir 显而易见
; mysql_dump_command mysql爱怎么导就怎么了，可以指定要导的数据库表...
; bak_days 备份保留的天数
; bak_freq 备份隔几天备一次

[d6:gitlab]
server=d6.bigxu.com
port=222
ssh_command=/home/bigxu/workspace/setup-config/fragment/d6-bak-gitlab.sh
dir=/data/backup/gitlab

[d6:nginx-conf]
server=d6.bigxu.com
port=222
dir=/home/soft/nginx/conf
bak_days=40
bak_freq=1

[d8:xunsearch]
server=d8.bigxu.com
port=222
dir=/data/www/xunsearch
mysql_dump_command=/usr/local/bin/mysqldump56 -uroot -ppassword --all-databases
bak_days=40
