#!/bin/bash

#Desnvolvido por: Bee Solutions
#Autor: Fernando Almonde
#Data: 15/05/2023

#Iniciando variaveis
PON=$1
STATUS=$2
IP=$3

if [[ ! -z $PON ]] && [[ ! -z $STATUS ]]; then

#Lista de ONUs por Slot 1.3.6.1.4.1.5875.800.3.10.1.1.2
#Lista de ONUs por porta 1.3.6.1.4.1.5875.800.3.10.1.1.3

#Status (OID Base ONU Status: 1.3.6.1.4.1.5875.800.3.10.1.1.11)
#0: los
#1: online
#2: offline
#3: sem dados
#4: dyinggasp

# Configurações de conexão com o banco de dados
DB_HOST="127.0.0.1"
DB_NAME="beesoft_db_01"

QUERY1="select count(onu.id) from beesoft_db_01.ftth_onucache onu
inner join ftth_olt olt on (onu.olt_fk_id = olt.id)
where SUBSTRING_INDEX(pon, '/', 2) = '"$PON"' and status=$STATUS and olt.ip='"$IP"'"

# Executa a consulta e imprime somente o valor com base no filtro
mysql --defaults-extra-file=/opt/bee/beesoft/.my.cnf -h $DB_HOST -D $DB_NAME --skip-column-names -e "$QUERY1" -B

else
echo 'Erro! Execute o script conforme o exemplo: ponfh "2/1" 1 "192.168.0.10"'

fi