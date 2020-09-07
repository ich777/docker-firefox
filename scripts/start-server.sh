#!/bin/bash
export DISPLAY=:99

#CUR_V="$(find ${DATA_DIR} -name instv* | cut -d 'v' -f2 )"
#LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/FlutterCoin | grep LATEST | cut -d '=' -f2)"

#if [ -z "$LAT_V" ]; then
#	if [ ! -z "$CUR_V" ]; then
#		echo "---Can't get latest version of FlutterCoin falling back to v$CUR_V---"
#		LAT_V="$CUR_V"
#	else
#		echo "---Something went wrong, can't get latest version of FlutterCoin, putting container into sleep mode---"
#		sleep infinity
#	fi
#fi

#echo "---Version Check---"
#if [ -z "$CUR_V" ]; then
#	echo "---FlutterCoin not installed, installing---"
#   cd ${DATA_DIR}
#	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/FlutterCoin-$LAT_V.zip https://github.com/ofeefee/fluttercoin/releases/download/v$LAT_V-flt/fluttercoin-64-linux-v$LAT_V.zip ; then
#    	echo "---Sucessfully downloaded FlutterCoin---"
#    else
#    	echo "---Something went wrong, can't download FlutterCoin, putting container in sleep mode---"
#        sleep infinity
#    fi
#	unzip -o ${DATA_DIR}/FlutterCoin-$LAT_V.zip
#	rm -R ${DATA_DIR}/FlutterCoin-$LAT_V.zip
#	touch ${DATA_DIR}/instv$LAT_V
#elif [ "$CUR_V" != "$LAT_V" ]; then
#	echo "---Version missmatch, installed v$CUR_V, downloading and installing latest v$LAT_V...---"
#    cd ${DATA_DIR}
#	find . -maxdepth 1 -type f -print0 | xargs -0 -I {} rm -R {} 2&>/dev/null
#	rm -R ${DATA_DIR}/themes 2>/dev/null
#	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/FlutterCoin-$LAT_V.zip https://github.com/ofeefee/fluttercoin/releases/download/v$LAT_V-flt/fluttercoin-64-linux-v$LAT_V.zip ; then
#    	echo "---Sucessfully downloaded FlutterCoin---"
#    else
#    	echo "---Something went wrong, can't download FlutterCoin, putting container in sleep mode---"
#        sleep infinity
#    fi
#	unzip -o ${DATA_DIR}/FlutterCoin-$LAT_V.zip
#	rm -R ${DATA_DIR}/FlutterCoin-$LAT_V.zip
#	touch ${DATA_DIR}/instv$LAT_V
#elif [ "$CUR_V" == "$LAT_V" ]; then
#	echo "---FlutterCoin v$CUR_V up-to-date---"
#fi

echo "---Preparing Server---"
echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W} ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H} ]; then
	CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1023 ]; then
	echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
	echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old display lock files---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
screen -wipe 2&>/dev/null

chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Starting Xvfb server---"
screen -S Xvfb -L -Logfile ${DATA_DIR}/XvfbLog.0 -d -m /opt/scripts/start-Xvfb.sh
sleep 2
echo "---Starting x11vnc server---"
screen -S x11vnc -L -Logfile ${DATA_DIR}/x11vncLog.0 -d -m /opt/scripts/start-x11.sh
sleep 2
echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem 8080 localhost:5900
sleep 2

echo "---Starting Firefox---"
cd ${DATA_DIR}
${DATA_DIR}/firefox ${EXTRA_PARAMS}