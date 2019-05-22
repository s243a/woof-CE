#!/bin/sh

. /etc/proxy.conf

if [ "$HTTP_PROXY_ADDRESS" != "" ] && [ "$HTTP_ENABLE" == "on" ]; then
 xUSER=""
	if [ "$HTTP_USERNAME" != "" ]; then
		if [ "$HTTP_PASSWORD" != "" ]; then
		 xUSER="$HTTP_USERNAME:$HTTP_PASSWORD@" 
		else
		 xUSER="$HTTP_USERNAME@"	
		fi
	fi

	if [ "$HTTP_PROXY_PORT" != "" ] && [ "$HTTP_PROXY_PORT" != "0" ]; then
	 PRX="http://${xUSER}${HTTP_PROXY_ADDRESS}:${HTTP_PROXY_PORT}"
	else
	 PRX="http://${xUSER}${HTTP_PROXY_ADDRESS}"	
	fi
	
 export http_proxy=$PRX
else
 unset http_proxy
fi


if [ "$HTTPS_PROXY_ADDRESS" != "" ] && [ "$HTTPS_ENABLE" == "on" ]; then
 xUSER=""
	if [ "$HTTPS_USERNAME" != "" ]; then
		if [ "$HTTPS_PASSWORD" != "" ]; then
		 xUSER="$HTTPS_USERNAME:$HTTPS_PASSWORD@" 
		else
		 xUSER="$HTTPS_USERNAME@"	
		fi
	fi

	if [ "$HTTPS_PROXY_PORT" != "" ] && [ "$HTTPS_PROXY_PORT" != "0" ]; then
	 PRX="http://${xUSER}${HTTPS_PROXY_ADDRESS}:${HTTPS_PROXY_PORT}"
	else
	 PRX="http://${xUSER}${HTTPS_PROXY_ADDRESS}"	
	fi
	
 export https_proxy=$PRX

else
 unset https_proxy
fi


if [ "$FTP_PROXY_ADDRESS" != "" ] && [ "$FTP_ENABLE" == "on" ]; then
 xUSER=""
	if [ "$FTP_USERNAME" != "" ]; then
		if [ "$FTP_PASSWORD" != "" ]; then
		 xUSER="$FTP_USERNAME:$FTP_PASSWORD@" 
		else
		 xUSER="$FTP_USERNAME@"	
		fi
	fi

	if [ "$FTP_PROXY_PORT" != "" ] && [ "$FTP_PROXY_PORT" != "0" ]; then
	 PRX="ftp://${xUSER}${FTP_PROXY_ADDRESS}:${FTP_PROXY_PORT}"
	else
	 PRX="ftp://${xUSER}${FTP_PROXY_ADDRESS}"	
	fi
	
 export ftp_proxy=$PRX
 
else
 unset ftp_proxy
fi
