#!/bin/bash
 
PORT=7777
IP_CLIENTE="localhost"
 
echo "LSTP Server (Lechuga Speaker Transfer Protocool)"
echo "0: LISTEN"
 
DATA=`nc -l $PORT`
echo "3: CHECK HEADER"
 
HEADER=`echo "$DATA" | cut -d " " -f 1`
 
if [ "$HEADER" != "LSTP_1" ] 
then
	echo "Error 1: Header mal formado :("
	echo "KO_HEADER" | nc $IP_CLIENTE $PORT
    exit 1
 
fi
IP_CLIENT=`echo "$DATA" | cut -d " " -f 2`

echo "4: SEND OK_HEADER"

echo "OK_HEADER" | nc $IP_CLIENTE $PORT
 


echo "5. Listen NUM_FILES"
DATA=`nc -l $PORT`
PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "NUM_FILES" ]
then
	echo "ERROR 2: Numero de archivos incorrecto (PREFIX MAL FORMADO)"
	echo "KO_NUM_FILES" | nc $IP_CLIENTE $PORT
	exit 2

NUM_FILES=`echo $DATA | cut -d " " -f 2`
NUM_FILES_CHECK=`echo "$NUM_FILES" | grep -E "^-?[0-9]+$"`

if [ "$NUM_FILES_CHECK" == "" ]
then
	echo "ERROR 2: Numero de archivos incorrecto"
	echo "KO_NUM_FILES" | nc $IP_CLIENTE $PORT
	exit 2
fi
if [ "$NUM_FILES" -lt 1 ]
then 
	echo"ERROR 30: Numero de archivos incorrecto es inferior a 1"
	exit 30
fi

echo "OK_NUM_FILES" | nc $IP_CLIENT $PORT

for NUM in `seq $NUM_FILES`
do

echo "5: LISTEN FILE_NAME"
DATA=`nc -l $PORT`

echo "9:CHECK FILE_NAME"
PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "FILE_NAME" ]
then
	echo "FILE NAME INCORRECTO O MAL FORMADO"
	echo "KO_FILE_NAME" | nc $IP_CLIENTE $PORT
	exit 2
fi

FILE_NAME=`echo "$DATA" | cut -d " " -f 2`
echo "10: SEND OK_FILE_NAME"
echo "OK_FILE_NAME" | nc $IP_CLIENTE $PORT
 

 

echo "11: LISTEN FILE DATA..."

nc -l $PORT > server/$FILE_NAME

echo "14:SEND KO/OK_FILE_DATA"

DATA=`cat server/$FILE_NAME | wc -c`
if [ "$DATA" -eq 0 ]
then
	echo "Error 3: Error al enviar los datos"
   	echo "KO_FILE_DATA" | nc $IP_CLIENTE $PORT
   	exit 3
fi
 
echo "OK_FILE_DATA" | nc $IP_CLIENT $PORT
 
echo "15: LISTEN FILE_MD5"
 
DATA=`nc -l $PORT`

PREFIX=`echo "$DATA" | cut -d " " -f 1`

if [ "$PREFIX" != "FILE_DATA_MD5" ] 
then
	echo "KO_FILE_DATA_MD5"
	exit 4
fi

MD5=`echo $DATA | cut -d " " -f 2`

MD5_LOCAL=`md5sum server/$FILE_NAME | cut -d " " -f 1`

if [ "$MD5" != "$MD5_LOCAL" ]
then
	echo "ERROR MD5 NO COINCIDEN"
	echo "KO_FILE_DATA_MD5" | nc $IP_CLIENT $PORT
	exit 5
fi

echo "OK_FILE_DATA_MD5" | nc $IP_CLIENT $PORT

done

echo "FIN"
exit 0

