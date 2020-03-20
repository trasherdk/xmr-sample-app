NETTYPES="mainnet testnet stagenet"
SESSIONS="xmr-app-daemon xmr-app-rpc"
PARAMS="daemon wallet"

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

start_daemon() {
	local SNAME="xmr-app-daemon"
	is_running ${SNAME} && return 1

	echo -n "${WHITE} Launching ${YELLOW} ${SNAME} : ${RESTORE}"

	local DAEMON="${BIN}/monerod"
	[ "${NETTYPE}" = "mainnet" ] || DAEMON="${DAEMON} --${NETTYPE}"

	local CMD="${DAEMON} \
		--prune-blockchain \
		--data-dir ${DATA} \
		--log-level 0 \
		--log-file ${LOGS}/monerod.log \
		--confirm-external-bind \
		--rpc-bind-ip '86.48.96.142' \
		--rpc-login superuser:abctesting123 \
		--rpc-access-control-origins 'http://86.48.96.142,https://86.48.96.142,http://xmr-app.fumlersoft.dk,https://xmr-app.fumlersoft.dk,http://digest-request.fumlersoft.dk,https://digest-request.fumlersoft.dk,fumlersoft.dk'" 

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
		--daemon-address '86.48.96.142:38081' \
		--daemon-login superuser:abctesting123 \
		--log-level 4 \
		--log-file ${LOGS}/monero-rpc.log \
		--confirm-external-bind \
		--rpc-bind-ip '86.48.96.142' \
		--rpc-bind-port 38083 \
		--wallet-dir ${WALLETS} \
		--rpc-login rpc_user:abc123 \
		--rpc-access-control-origins 'http://86.48.96.142,https://86.48.96.142,http://xmr-app.fumlersoft.dk,https://xmr-app.fumlersoft.dk,http://digest-request.fumlersoft.dk,https://digest-request.fumlersoft.dk,fumlersoft.dk'" 
#		--disable-rpc-login \

	screen -S "${SNAME}-${NETTYPE}" -d -m  bash -c "${CMD}" \
	&& { echo ${GREEN}OK${RESTORE}; } \
	|| { echo ${RED}FAIL${RESTORE}; }

	[ ${VERBOSE} -eq 1 ] && echo "${CMD}"
}
