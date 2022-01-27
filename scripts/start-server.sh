#!/bin/bash
export DISPLAY=:99

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
else
	if [ ! -z "$(grep "unraid" ${DATA_DIR}/mozilla.cfg)" ]; then
		rm ${DATA_DIR}/mozilla.cfg
		cp /tmp/config/mozilla.cfg ${DATA_DIR}/mozilla.cfg
	fi
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
rm -rf /tmp/.X99*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid
chmod -R ${DATA_PERM} ${DATA_DIR}
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
	chmod 600 ${DATA_DIR}/.vnc/passwd
fi
screen -wipe 2&>/dev/null

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
/usr/bin/firefox-esr --display=:99 --profile ${DATA_DIR}/profile --P ${USER} --setDefaultBrowser ${EXTRA_PARAMETERS}