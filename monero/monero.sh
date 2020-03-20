#!/usr/bin/env bash

BASE=$(realpath "$(dirname $0)/..")

NETTYPE="stagenet"
DATA=/var/lib/monero/data/${NETTYPE}
WALLETS=${DATA}/wallets
LOGS=${DATA}/logs
BIN=/var/lib/monero/bin
CERTS=$(dirname ${BIN})/certs
VERBOSE=0

source ${BASE}/monero/monero-scripts.sh
source ${BASE}/monero/colors.sh

[ -d ${DATA} ] || mkdir -p ${DATA}
[ -d ${WALLETS} ] || mkdir -p ${WALLETS}
[ -d ${LOGS} ] || mkdir -p ${LOGS}

echo "Network Type........: ${NETTYPE}"
echo "Working directory...: ${BASE}"
echo "Data directory......: ${DATA}"
echo "Wallets directory...: ${WALLETS}"
echo "Logs directory......: ${LOGS}"
echo "Monero binaries.....: ${BIN}"
echo "Monero certificates.: ${CERTS}"

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
    echo "Data directory OK"
  } \
  || {
  echo "Missing data directory: ${DATA}"
  exit 1
  }

while [ $# -gt 0 ]
do
  case "$1" in
    "verbose")
      shift
      VERBOSE=1
      ;;
    "ls")
      shift
      screen -ls | grep -i "xmr"
      ;;
    "stop")
      shift
      while [ $# -gt 0 ]
      do
        is_valid_parameter $1 || break
        NAME=$1
        shift
        case "${NAME}" in
          "daemon")
            stop_daemon
            ;;
          "wallet")
            stop_wallet
            ;;
          "wallet-ssl")
            stop_ssl_wallet
            ;;
          *)
            echo "Unknown parameter: ${NAME}"
            break
            ;;
        esac
      done
      ;;
    "start")
      shift
      while [ $# -gt 0 ]
      do
        is_valid_parameter $1 || break
        NAME=$1
        shift
        case "${NAME}" in
          "daemon")
            start_daemon
            ;;
          "wallet")
            start_wallet
            ;;
          "wallet-ssl")
            start_ssl_wallet
            ;;
          *)
            echo "Unknown parameter: ${NAME}"
            break
            ;;
        esac
      done
      ;;
    "restart")
      shift
      while [ $# -gt 0 ]
      do
        is_valid_parameter $1 || break
        NAME=$1
        shift
        case "${NAME}" in
          "daemon")
            stop_daemon
            start_daemon
            ;;
          "wallet")
            stop_wallet
            start_wallet
            ;;
          "wallet-ssl")
            stop_ssl_wallet
            start_ssl_wallet
            ;;
          *)
            echo "Unknown parameter: ${NAME}"
            break
            ;;
        esac
      done
      ;;
    *)
      echo "Unknown command: $1"
      shift
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
