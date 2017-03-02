#!/bin/bash
IFS_DEFUALT=$IFS

DIR=$(dirname $0)
INI_FILE=$DIR/servers.ini
source $DIR/parser/iniParser.bash


# test
IFS=$IFS_DEFUALT
for section in $(get_sections);
do
    TITLE=$(get_value $section 'title')
    echo $TITLE
done

ORIGIN_DIR=/data/rsync/origin
BAK_DIR=/data/rsync/bak
MYSQL_DUMP_PREFIX='bak-name-md5xafdsafds0afds'
DAY=$(($(date +%s) / 86400))
ALL_LOG=/home/bigxu/tmp/$(date +%Y-%m-%d).all-rsync2-bak.txt
rm -f $ALL_LOG

# ssh command
IFS=$IFS_DEFUALT
for section in $(get_sections);
do
    # get var
    TITLE=$(get_value $section 'title')
    PORT=$(get_value $section 'port')
    SERVER=$(get_value $section 'server')
    SSH_COMMAND=$(get_value $section 'ssh_command')

    if [[ ! -z $SSH_COMMAND ]];then 
        echo "!!! $TITLE ssh command " >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) $SERVER ssh command " >> $ALL_LOG 2>&1
        START=$(date +'%s')
        echo "ssh -n -p $PORT $SERVER \"$SSH_COMMAND\" 2>&1 " >> $ALL_LOG 2>&1
        ssh -n -p $PORT $SERVER "$SSH_COMMAND 2>&1 " >> $ALL_LOG 2>&1
        echo "It took $(($(date +'%s') - $START)) seconds" >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) end" >> $ALL_LOG
    fi
done

# mysqldump
IFS=$IFS_DEFUALT
for section in $(get_sections);
do
    # get var
    TITLE=$(get_value $section 'title')
    PORT=$(get_value $section 'port')
    SERVER=$(get_value $section 'server')
    DIR=$(get_value $section 'dir')
    MYSQL_DUMP_COMMAND=$(get_value $section 'mysql_dump_command')

    # mysqldump
    if [[ ! -z $MYSQL_DUMP_COMMAND ]];then 
        echo "!!! $TITLE mysqldump" >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) $SERVER $DIR mysqldump start" >> $ALL_LOG
        START=$(date +'%s')
        MYSQL_DUMP_NAME=$MYSQL_DUMP_PREFIX.$(date +%Y-%m-%d-%H-%M-%S).sql
        echo "ssh -n -p $PORT $SERVER \"cd $DIR; rm -f ${MYSQL_DUMP_PREFIX}*sql; $MYSQL_DUMP_COMMAND > $MYSQL_DUMP_NAME\""  >> $ALL_LOG 2>&1
        ssh -n -p $PORT $SERVER "cd $DIR; rm -f ${MYSQL_DUMP_PREFIX}*sql; $MYSQL_DUMP_COMMAND > $MYSQL_DUMP_NAME"  >> $ALL_LOG 2>&1
        echo "It took $(($(date +'%s') - $START)) seconds" >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) end" >> $ALL_LOG
    fi
done

# rsync
for section in `get_sections`;
do
    # get var
    TITLE=$(get_value $section 'title')
    echo "!!! $TITLE rsync" >> $ALL_LOG
    PORT=$(get_value $section 'port')
    SERVER=$(get_value $section 'server')
    DIR=$(get_value $section 'dir')
    EXCLUDE=$(get_value $section 'exclude')
    #--exclude "/config/custom.php"

    # create $TARGET_DIR
    TARGET_DIR=$ORIGIN_DIR/$SERVER
    mkdir -p $TARGET_DIR

    # rsync
    if [[ ! -z $DIR ]];then 
        echo "$(date +%Y-%m-%d\ %H:%M:%S) $SERVER $DIR rsync start" >> $ALL_LOG
        START=$(date +'%s')
        echo "/usr/bin/rsync -e \"ssh -p $PORT\" -azpR  --delete $EXCLUDE root@$SERVER:$DIR $TARGET_DIR" >> $ALL_LOG 2>&1
        /usr/bin/rsync -e "ssh -p $PORT" -azpR --delete $EXCLUDE root@$SERVER:$DIR $TARGET_DIR >> $ALL_LOG 2>&1
        echo "It took $(($(date +'%s') - $START)) seconds" >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) end" >> $ALL_LOG
    fi
done


# bak
IFS=$IFS_DEFUALT
for section in `get_sections`;
do
    # get var
    TITLE=$(get_value $section 'title')
    PORT=$(get_value $section 'port')
    SERVER=$(get_value $section 'server')
    DIR=$(get_value $section 'dir')
    BAK_FREQ=$(get_value $section 'bak_freq')
    BAK_DAYS=$(get_value $section 'bak_days')

    STORE_DIR=$BAK_DIR/$SERVER/$DIR
    mkdir -p $STORE_DIR

    # bak
    if [[ $BAK_DAYS > 0 ]];then
        echo "[[ $BAK_DAYS > 0 &&  $(($DAY % $BAK_FREQ )) == 0 ]] || [[ $(ls $STORE_DIR|wc -l) == 0 ]] " >> $ALL_LOG
    fi

    if [[ $BAK_DAYS > 0 &&  $(($DAY % $BAK_FREQ )) == 0 ]] || [[ $(ls $STORE_DIR|wc -l) == 0 ]];then
        echo "!!! $TITLE bak" >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) $SERVER $DIR bak start" >> $ALL_LOG
        START=$(date +'%s')

        TARGET_DIR=$ORIGIN_DIR/$SERVER
        mkdir -p $STORE_DIR
        find $STORE_DIR -mtime +$BAK_DAYS -exec rm -rf {} \;
        cd $TARGET_DIR
        FILE_NAME=$(date +%Y-%m-%d).$(date +%s)
        rm -f $STORE_DIR/$FILE_NAME.tgz
        echo "tar --use-compress-program=lzop -cf $STORE_DIR/$FILE_NAME.tar.lzo ${DIR:1}" >> $ALL_LOG 2>&1
        tar --use-compress-program=lzop -cf $STORE_DIR/$FILE_NAME.tar.lzo ${DIR:1} >> $ALL_LOG 2>&1
        echo "It took $(($(date +'%s') - $START)) seconds" >> $ALL_LOG
        echo "$(date +%Y-%m-%d\ %H:%M:%S) end" >> $ALL_LOG
    fi
done

/usr/local/bin/php  /home/bigxu/workspace/setup-config/mail/send.php subject="D5: new rsync $ALL_LOG $(date +%Y-%m-%d\ %H:%I:%S)" content=$ALL_LOG attachments=$ALL_LOG
