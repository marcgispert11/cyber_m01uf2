#!/bin/bash

if [ $# -ne 1 ]
then 
	echo "Error: El comando requiere al menos un parametro"
	echo "Ejemplo de uso:"
	echo  "$0 127.0.0.1"
	exit 100
fi


PORT=7777
IPSERVER=$1
IPCLIENT=`ip a | grep -i inet | grep -i global | awk '{print $2}' | cut -d "/" -f1`

WORKING_DIR="cliente"

echo "LSTP Client (Lechuga Speaker Transfer Protocol)"
echo "1: SEND HEADER (Client: $IPCLIENT, SERVER: $IPSERVER)"



echo "LSTP_1 $IPCLIENT" | nc $IPSERVER $PORT

echo "2: LISTEN"

DATA=`nc -l $PORT`

if [ "$DATA" != "OK_HEADER" ]
then
echo "Error 1: Header mal formado :("
exit 1
fi


#cat client/lechuga1.lechu | text2wave -o client/lechu.wav
#yes | ffmpeg -i client/lechu.wave client/lechu.ogg


echo "7.1 SEND NUM_FILES"
NUM_FILES=`ls $WORKING_DIR/*.lechu | wc -l`
echo "NUM_FILES $NUM_FILES" | nc $IPSERVER $PORT

DATA=`nc -l $PORT`
echo "7.2 CHECK OK_NUM_FILES"
if [ "$DATA" != "OK_NUM_FILES" ]
then
	echo "ERROR 2: NUM FILES no enviado o enviado incorrectamente"
	exit 2
fi
echo "7.3 SEND FILES"

for FILE_NAME in `ls $WORKING_DIR/*.lechu`
do


echo "7:ENVIAR EL FILE_NAME"
FILE_NAME=`basename $FILE_NAME`
echo "sleep" | sleep 1
echo "FILE_NAME $FILE_NAME" | nc $IPSERVER $PORT

echo "8:LISTEN"
DATA=`nc -l $PORT`
if [ "$DATA" != "OK_FILE_NAME" ]
then
	echo "Error FILE_NAME mal enviado"
	exit 2
fi

echo "12:SEND FILE DATA"
cat $WORKING_DIR/$FILE_NAME | nc $IPSERVER $PORT
 
echo "13.LISTEN"
DATA=`nc -l $PORT`

if [ "$DATA" != "OK_FILE_DATA" ]
	then
    echo "ERROR AL ENVIAR LOS DATOS :("
    exit 4
fi


echo "16. SEND FILE_MD5"

MD5=`cat $WORKING_DIR/$FILE_NAME | md5sum | cut -d " " -f 1`


echo "FILE_DATA_MD5 $MD5" | nc $IPSERVER $PORT

echo "18:LISTEN"
DATA=`nc -l $PORT`
if [ "$DATA" != "OK_FILE_DATA_MD5" ]
then
	echo "ERROR 5. MD5 no enviado o enviado incorrectamente"
	exit 5
fi
echo "MD5 FILE_DATA: $DATA"

sleep 1

done

echo "Fin"
exit 0
