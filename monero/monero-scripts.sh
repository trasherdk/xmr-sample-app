NETTYPES="mainnet testnet stagenet"
SESSIONS="xmr-app-daemon xmr-app-rpc xmr-app-rpc-ssl"
PARAMS="daemon wallet wallet-ssl"
CORS="http://86.48.96.142,https://86.48.96.142,http://xmr-app.fumlersoft.dk,https://xmr-app.fumlersoft.dk,http://digest-request.fumlersoft.dk,https://digest-request.fumlersoft.dk,fumlersoft.dk"
HOST="86.48.96.142"

declare -A CERTS_SHA256
CERTS_SHA256[ca]="34:C9:93:F4:61:A5:79:BE:2F:68:2E:80:65:F5:41:0F:0B:D2:D4:75:9A:62:76:26:07:9C:8A:AD:D4:A8:75:DF"
CERTS_SHA256[compaq]="CC:23:5F:C4:4C:36:21:82:C9:60:31:38:B2:E6:10:9F:CA:5B:50:25:AB:95:23:72:C2:74:7A:60:1A:F3:93:A0"
CERTS_SHA256[firefox]="FA:29:3D:3D:BF:9B:02:EA:0C:54:04:A2:B8:F7:C7:3E:BD:75:5E:CF:A3:DE:98:1F:22:12:67:38:66:22:3F:B2"
CERTS_SHA256[digest]="AA:3D:B9:BC:47:E4:FA:94:56:A8:92:F4:65:D9:2F:56:BC:C6:31:B0:81:BF:AB:0F:71:27:76:F6:28:BA:E1:93"
CERTS_SHA256[ghost-m1]="39:47:BA:65:4F:E3:C0:79:B5:CF:E6:1E:C3:D6:34:52:4A:F1:BC:F9:51:6E:37:CB:56:3A:6D:56:55:BD:DF:DC"
CERTS_SHA256[letsencrypt]="FE:6F:7F:6C:6C:AE:93:70:D0:1B:45:85:D0:67:BE:FB:9D:E6:0A:7A:A1:96:D0:4F:AB:A4:3B:04:3C:C2:6B:51"

is_running() {
	local NAME="$1"

	is_valid_session ${NAME} || return 1

	local SNAME
	for SNAME in $(screen -ls| grep -P '\d\.[a-zA-Z0-9\-]' | cut -f2 -d$'\t'|cut -f2 -d'.')
	do
		#echo "${WHITE}${SNAME} = ${NAME}${RESTORE}"
		[ "${SNAME}" = "${NAME}-${NETTYPE}" ] \
			&& {
				echo "${GREEN}${SNAME}${WHITE} is running..${RESTORE}"
				return 0
			}
	done

  echo "${RED}${NAME}${WHITE} is not running..${RESTORE}"
	return 1
}

is_valid_parameter() {

	[[ ${PARAMS} =~ (^|[[:space:]])$1($|[[:space:]]) ]] \
	|| {
		echo "${RED} Invalid parameter name: ${YELLOW} $1 ${RESTORE}"
		echo "${WHITE}Valid parameter names: ${YELLOW}${PARAMS}${RESTORE}"
  	return 1
	}

	return 0
}

is_valid_nettype() {

	[[ ${NETTYPES} =~ (^|[[:space:]])$1($|[[:space:]]) ]] \
	|| {
		echo "${RED} Invalid nettype name: ${YELLOW} $1 ${RESTORE}"
		echo "${WHITE}Valid nettype names: ${YELLOW}${NETTYPES}${RESTORE}"
  	return 1
	}

	return 0
}

is_valid_session() {

	[[ ${SESSIONS} =~ (^|[[:space:]])$1($|[[:space:]]) ]] \
	|| {
		echo "${RED} Invalid session name: ${YELLOW} $1 ${RESTORE}"
		echo "${WHITE}Valid session names: ${YELLOW}${SESSIONS}${RESTORE}"
		return 1
	}

	return 0
}

stop_one() {
	local SNAME=$1

	is_valid_session ${SNAME} || return 1
	is_running ${SNAME} || return 1
	echo "${WHITE} Terminating ${YELLOW} ${SNAME} ${RESTORE}"
	screen -X -S "${SNAME}-${NETTYPE}" quit

}

stop_daemon() {
	local SNAME="xmr-app-daemon"
	is_running ${SNAME} || return 1
	echo "${WHITE} Terminating ${YELLOW} ${SNAME} ${RESTORE}"
	screen -X -S "${SNAME}-${NETTYPE}" quit
}

stop_wallet() {
	local SNAME="xmr-app-rpc"
	is_running ${SNAME} || return 1
	echo "${WHITE} Terminating ${YELLOW} ${SNAME} ${RESTORE}"
	screen -X -S "${SNAME}-${NETTYPE}" quit
}

stop_ssl_wallet() {
	local SNAME="xmr-app-rpc-ssl"
	is_running ${SNAME} || return 1
	echo "${WHITE} Terminating ${YELLOW} ${SNAME} ${RESTORE}"
	screen -X -S "${SNAME}-${NETTYPE}" quit
}

start_daemon() {
	local SNAME="xmr-app-daemon"
	is_running ${SNAME} && return 1

	echo -n "${WHITE} Launching ${YELLOW} ${SNAME} : ${RESTORE}"

	local DAEMON="${BIN}/monerod"
	[ "${NETTYPE}" = "mainnet" ] || DAEMON="${DAEMON} --${NETTYPE}"

	local CMD="${DAEMON} \
		--prune-blockchain \
		--data-dir ${DATA} \
		--log-level '0,net.throttle:ERROR,net.http:TRACE' \
		--log-file ${LOGS}/monerod.log \
		--confirm-external-bind \
		--rpc-bind-ip '${HOST}' \
		--rpc-login superuser:abctesting123 \
		--rpc-access-control-origins '${CORS}'" 

	screen -S "${SNAME}-${NETTYPE}" -d -m  bash -c "${CMD}" \
	&& { echo ${GREEN}OK${RESTORE}; } \
	|| { echo ${RED}FAIL${RESTORE}; }

	[ ${VERBOSE} -eq 1 ] && echo "${CMD}"
}

start_wallet() {
	local SNAME="xmr-app-rpc"
	is_running ${SNAME} && return 1

	echo -n "${WHITE} Launching ${YELLOW} ${SNAME} : ${RESTORE}"

	local RPC="${BIN}/monero-wallet-rpc"
	[ "${NETTYPE}" = "mainnet" ] || RPC="${RPC} --${NETTYPE}"

	local CMD="${RPC} \
		--daemon-address '${HOST}:38081' \
		--daemon-login superuser:abctesting123 \
		--daemon-ssl-allow-any-cert \
		--wallet-dir ${WALLETS} \
		--log-level '2,net.throttle:ERROR,net.http:TRACE' \
		--log-file ${LOGS}/monero-rpc.log \
		--confirm-external-bind \
		--rpc-bind-ip '${HOST}' \
		--rpc-bind-port 38083 \
		--rpc-login rpc_user:abc123 \
		--rpc-access-control-origins '${CORS}'" 
#		--disable-rpc-login \

	screen -S "${SNAME}-${NETTYPE}" -d -m  bash -c "${CMD}" \
	&& { echo ${GREEN}OK${RESTORE}; } \
	|| { echo ${RED}FAIL${RESTORE}; }

	[ ${VERBOSE} -eq 1 ] && echo "${CMD}"
}

start_ssl_wallet() {
	local SNAME="xmr-app-rpc-ssl"
	is_running ${SNAME} && return 1

	echo -n "${WHITE} Launching ${YELLOW} ${SNAME} : ${RESTORE}"

	local RPC="${BIN}/monero-wallet-rpc"
	[ "${NETTYPE}" = "mainnet" ] || RPC="${RPC} --${NETTYPE}"

	local CMD="${RPC} \
		--daemon-address '${HOST}:38081' \
		--daemon-login superuser:abctesting123 \
		--daemon-ssl-allow-any-cert \
		--log-level '2,net.throttle:ERROR,net.http:TRACE' \
		--log-file ${LOGS}/monero-rpc.log \
		--confirm-external-bind \
		--rpc-bind-ip '${HOST}' \
		--rpc-bind-port 38084 \
		--rpc-ssl-private-key ${CERTS}/monero-rpc.key \
		--rpc-ssl-certificate ${CERTS}/monero-rpc.crt \
		--rpc-ssl-ca-certificates ${CERTS}/ca.crt \
		--rpc-ssl-allowed-fingerprints '${CERTS_SHA256[ca]}' \
		--rpc-ssl-allowed-fingerprints '${CERTS_SHA256[compaq]}' \
		--rpc-ssl-allowed-fingerprints '${CERTS_SHA256[firefox]}' \
		--rpc-ssl-allowed-fingerprints '${CERTS_SHA256[digest]}' \
		--rpc-ssl-allowed-fingerprints '${CERTS_SHA256[ghost-m1]}' \
		--rpc-ssl-allowed-fingerprints '${CERTS_SHA256[letsencrypt]}' \
		--wallet-dir ${WALLETS} \
		--rpc-login rpc_user:abc123 \
		--rpc-access-control-origins '${CORS}'" 
#		--disable-rpc-login \

	screen -S "${SNAME}-${NETTYPE}" -d -m  bash -c "${CMD}" \
	&& { echo ${GREEN}OK${RESTORE}; } \
	|| { echo ${RED}FAIL${RESTORE}; }

	[ ${VERBOSE} -eq 1 ] && echo "${CMD}"
}
