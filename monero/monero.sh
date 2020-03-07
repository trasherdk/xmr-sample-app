#!/usr/bin/env bash

BASE=$(realpath "$(dirname $0)/..")

NETTYPE="stagenet"
DATA=/var/lib/monero/data/${NETTYPE}
WALLETS=${DATA}/wallets
LOGS=${DATA}/logs
BIN=/var/lib/monero/bin

source ${BIN}/monero-scripts.sh
source ${BIN}/colors.sh

[ -d ${DATA} ] || mkdir -p ${DATA}
[ -d ${WALLETS} ] || mkdir -p ${WALLETS}
[ -d ${LOGS} ] || mkdir -p ${LOGS}

echo "Network Type........: ${NETTYPE}"
echo "Working directory...: ${BASE}"
echo "Data directory......: ${DATA}"
echo "Wallets directory...: ${WALLETS}"
echo "Logs directory......: ${LOGS}"
echo "Monero binaries.....: ${BIN}"

[ -f ${BIN}/monerod ] \
|| {
  echo "This script expects to find monero binaries in:"
  echo "\$BIN ${BIN}"
  echo "If you have the monero binaries in another localion,"
  echo "change the BIN variable to point to that location."
  exit 1
}

[ -d ${DATA} ] \
&& {
  [ "${NETTYPE}" = "mainnet" ] \
  && {

  }
} \
|| {
  echo "Missing data directory: "
}

while [ $# -gt 0 ]
do
  case "$1" in
    "ls")
      shift
      screen -ls | grep -i "xmr"
      ;;
    "stop")
      shift
      is_valid_parameter $1 || break
      while [ $# -gt 0 ]
      do
        NAME=$1
        case "${NAME}" in
          "daemon")
            stop_daemon
            ;;
          "wallet")
            stop_wallet
            ;;
          *)
            #echo "Unknown session: ${NAME}"
            break
            ;;
        esac
        shift
      done
      ;;
    "start")
      shift
      is_valid_parameter $1 || break
      while [ $# -gt 0 ]
      do
        NAME=$1
        case "${NAME}" in
          "daemon")
            start_daemon
            ;;
          "wallet")
            start_wallet
            ;;
          *)
            #echo "Unknown session: ${NAME}"
            break
            ;;
        esac
        shift
      done
      ;;
    "restart")
      shift
      is_valid_parameter $1 || break
      while [ $# -gt 0 ]
      do
        NAME=$1
        case "${NAME}" in
          "daemon")
            stop_daemon
            start_daemon
            ;;
          "wallet")
            stop_wallet
            start_wallet
            ;;
          *)
            #echo "Unknown session: ${NAME}"
            break
            ;;
        esac
        shift
      done
      ;;
  esac
done

while [ $# -gt 0 ]
do
  echo "Unknown session: ${1}"
  shift
done

screen -ls | grep 'xmr-app'

exit
