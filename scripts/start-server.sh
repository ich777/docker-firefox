#!/bin/bash
export DISPLAY=:99
CUR_V="$(${DATA_DIR}/firefox --version 2>/dev/null | cut -d ' ' -f3)"
if [ "${FIREFOX_V}" == "latest" ]; then
	LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/Firefox | grep LATEST | cut -d '=' -f2)"
	sleep 2
	FIREFOX_V="${LAT_V}"
	if [ -z "$LAT_V" ]; then
		if [ ! -z "$CUR_V" ]; then
			echo "---Can't get latest version of Firefox falling back to v$CUR_V---"
			LAT_V="$CUR_V"
		else
			echo "---Something went wrong, can't get latest version of Firefox, putting container into sleep mode---"
			sleep infinity
		fi
	fi
fi

echo "---Version Check---"
if [ -z "$CUR_V" ]; then
	echo "---Firefox not installed, installing---"
	cd ${DATA_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Firefox-$LAT_V-$FIREFOX_LANG.tar.bz2 "https://download.mozilla.org/?product=firefox-${FIREFOX_V}&os=linux64&lang=${FIREFOX_LANG}" ; then
		echo "---Sucessfully downloaded Firefox---"
	else
		echo "---Something went wrong, can't download Firefox, putting container in sleep mode---"
		sleep infinity
	fi
	tar -C ${DATA_DIR} --strip-components=1 -xf ${DATA_DIR}/Firefox-$LAT_V-$FIREFOX_LANG.tar.bz2
	rm -R ${DATA_DIR}/Firefox-$LAT_V-$FIREFOX_LANG.tar.bz2
elif [ "$CUR_V" != "$LAT_V" ]; then
	echo "---Version missmatch, installed v$CUR_V, downloading and installing latest v$LAT_V...---"
    cd ${DATA_DIR}
	find . -maxdepth 1 ! -name profile -exec rm -r {} \; 2>/dev/null
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Firefox-$LAT_V-$FIREFOX_LANG.tar.bz2 "https://download.mozilla.org/?product=firefox-${FIREFOX_V}&os=linux64&lang=${FIREFOX_LANG}" ; then
		echo "---Sucessfully downloaded Firefox---"
	else
		echo "---Something went wrong, can't download Firefox, putting container in sleep mode---"
		sleep infinity
	fi
	tar -C ${DATA_DIR} --strip-components=1 -xf ${DATA_DIR}/Firefox-$LAT_V-$FIREFOX_LANG.tar.bz2
	rm -R ${DATA_DIR}/Firefox-$LAT_V-$FIREFOX_LANG.tar.bz2
elif [ "$CUR_V" == "$LAT_V" ]; then
	echo "---Firefox v$CUR_V up-to-date---"
fi

echo "---Preparing Server---"
if [ ! -d ${DATA_DIR}/profile ]; then
	mkdir -p ${DATA_DIR}/profile
fi
if [ ! -d ${DATA_DIR}/defaults/pref ]; then
	mkdir -p ${DATA_DIR}/defaults/pref
fi
if [ ! -f ${DATA_DIR}/defaults/pref/autoconfig.js ]; then
	cp /tmp/config/autoconfig.js ${DATA_DIR}/defaults/pref/autoconfig.js
fi
if [ ! -f ${DATA_DIR}/mozilla.cfg ]; then
	cp /tmp/config/mozilla.cfg ${DATA_DIR}/mozilla.cfg
fi
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
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}
sleep 2

echo "---Starting Firefox---"
cd ${DATA_DIR}
${DATA_DIR}/firefox --display=:99 --profile ${DATA_DIR}/profile --P ${USER} --setDefaultBrowser ${EXTRA_PARAMETERS}