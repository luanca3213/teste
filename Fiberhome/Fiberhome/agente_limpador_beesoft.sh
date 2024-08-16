#!/bin/bash

#Desenvolvido por: Bee Solutions
#Autor: Fernando Almondes
#Data: 02/08/2023 19h43m

DATA_EXE=$(date "+%d-%m-%Y_%H-%M-%S")
echo -e "----------------------------------------------------------"
echo -e "--> Inicio da execucao: $DATA_EXE <--"
echo -e "----------------------------------------------------------\n"

DIR_01="/opt/bee/beesoft"
DIR_02="/opt/bee/tmp/listas"

DATA=$(date "+%d-%m-%Y-%Hh-%Mm")

OLT=$1
DIAS=$2
CHAT_ID=$3

if [[ -z "$OLT" ]] && [[ -z "$DIAS" ]] && [[ -z "$CHAT_ID" ]]; then

 echo "--> Informe o chat-id, filtro da OLT e o numero de dias..."
 echo "--> Para OLT especifica: ./agente_limpador_telegram.sh 'OLT-CLIENTE-X' '7' '-12345'"
 echo "--> Para Todas as OLTs: ./agente_limpador_telegram.sh 'OLT' '7' '-12345'"

 DATA_EXE=$(date "+%d-%m-%Y_%H-%M-%S")
 echo -e "\n----------------------------------------------------------"
 echo -e "--> Fim da execucao: $DATA_EXE <--"
 echo -e "----------------------------------------------------------"

 exit 1

fi

# Defina aqui o host e a database
DB_HOST="localhost"
DB_NAME="beesoft_db_01"

limpar_dados_bd() {

echo "-> Removendo dados do banco de dados..."

# Lista de ONUs a serem removidas
QUERY1="DELETE onu
  FROM ftth_onu onu
  INNER JOIN ftth_olt olt ON (olt.id = onu.olt_fk_id)
  WHERE onu.timestamp < DATE_SUB(NOW(), INTERVAL '"$DIAS"' DAY) AND olt.nome like '"%$OLT%"';
"

# Lista do historico de sinal a ser removido
QUERY2="DELETE oh
  FROM ftth_onuhistory oh
  INNER JOIN ftth_olt olt ON (olt.id = oh.olt_fk_id)
  INNER JOIN ftth_onu onu ON (onu.id = oh.onu_fk_id)
  WHERE oh.onu_fk_id IN (SELECT onu.id FROM ftth_onu onu INNER JOIN ftth_olt olt ON (olt.id = onu.olt_fk_id) WHERE onu.timestamp < DATE_SUB(NOW(), INTERVAL '"$DIAS"' DAY) AND olt.nome like '"%$OLT%"');
"

# Lista de ONUs a serem removidas
QUERY3="DELETE onu
  FROM ftth_onucache onu
  INNER JOIN ftth_olt olt ON (olt.id = onu.olt_fk_id)
  WHERE onu.timestamp < DATE_SUB(NOW(), INTERVAL '"$DIAS"' DAY) AND olt.nome like '"%$OLT%"';
"

# Removendo historico primeiro
mysql --defaults-extra-file=$DIR_01/.my.cnf -h $DB_HOST -D $DB_NAME -e "$QUERY2"
# Agora removendo as ONUs | Geral
mysql --defaults-extra-file=$DIR_01/.my.cnf -h $DB_HOST -D $DB_NAME -e "$QUERY1"
# Agora removendo as ONUs | Cache
mysql --defaults-extra-file=$DIR_01/.my.cnf -h $DB_HOST -D $DB_NAME -e "$QUERY3"

}

gera_listas() {

# Lista de ONUs a serem removidas
QUERY1="SELECT
  olt.nome AS OLT,
  onu.onuid AS ONUID,
  onu.pon AS PON,
  onu.serial AS SN,
  onu.description AS 'DESCRIÇÃO',
  onu.distance AS 'DISTANCIA',
  onu.model AS MODELO,
  onu.version AS VERSAO,
  onu.status AS STATUS,
  onu.reason AS 'ULT.MOT.OFF',
  DATE_FORMAT(onu.last_uptime, '%d-%m-%Y %H:%i:%s') AS 'ULT.VEZ.ONLINE',
  DATE_FORMAT(onu.last_downtime, '%d-%m-%Y %H:%i:%s') AS 'ULT.VEZ.OFFLINE',
  DATE_FORMAT(CONVERT_TZ(onu.timestamp, '+00:00', '-03:00'), '%d-%m-%Y %H:%i:%s') AS 'ULT.VERIFICACAO'
  FROM ftth_onu onu
  INNER JOIN ftth_olt olt ON (olt.id = onu.olt_fk_id)
  WHERE onu.timestamp < DATE_SUB(NOW(), INTERVAL '"$DIAS"' DAY) AND olt.nome like '"%$OLT%"';
"

mysql --defaults-extra-file=$DIR_01/.my.cnf -h $DB_HOST -D $DB_NAME -e "$QUERY1" -B -r | sed 's/\t/,/g' > $DIR_02/lista_onus_a_serem_removidas_"$DATA".csv

# Lista do historico de sinal a ser removido
QUERY2="SELECT
  olt.nome AS OLT,
  onu.id AS ONUID,
  onu.pon AS PON,
  onu.serial AS SERIAL,
  oh.onurx AS ONURX,
  oh.onutx AS ONUTX,
  oh.oltrx AS OLTRX,
  oh.timestamp AS 'ULT.VERIFICACAO'
  FROM ftth_onuhistory oh
  INNER JOIN ftth_olt olt ON (olt.id = oh.olt_fk_id)
  INNER JOIN ftth_onu onu ON (onu.id = oh.onu_fk_id)
  WHERE oh.onu_fk_id IN (SELECT onu.id FROM ftth_onu onu INNER JOIN ftth_olt olt ON (olt.id = onu.olt_fk_id) WHERE onu.timestamp < DATE_SUB(NOW(), INTERVAL '"$DIAS"' DAY) AND olt.nome like '"%$OLT%"');
"

mysql --defaults-extra-file=$DIR_01/.my.cnf -h $DB_HOST -D $DB_NAME -e "$QUERY2" -B -r | sed 's/\t/,/g' > $DIR_02/lista_historico_a_ser_removido_"$DATA".csv

# Lista de ONUs a serem removidas
QUERY3="SELECT
  olt.nome AS OLT,
  onu.onuid AS ONUID,
  onu.pon AS PON,
  onu.serial AS SN,
  onu.status AS STATUS,
  DATE_FORMAT(CONVERT_TZ(onu.timestamp, '+00:00', '-03:00'), '%d-%m-%Y %H:%i:%s') AS 'ULT.VERIFICACAO'
  FROM ftth_onucache onu
  INNER JOIN ftth_olt olt ON (olt.id = onu.olt_fk_id)
  WHERE onu.timestamp < DATE_SUB(NOW(), INTERVAL '"$DIAS"' DAY) AND olt.nome like '"%$OLT%"';
"

mysql --defaults-extra-file=$DIR_01/.my.cnf -h $DB_HOST -D $DB_NAME -e "$QUERY3" -B -r | sed 's/\t/,/g' > $DIR_02/lista_onuscache_a_serem_removidas_"$DATA".csv

TOTAL_ONUS=$(cat $DIR_02/lista_onus_a_serem_removidas_"$DATA".csv | sed '1d' | wc -l)
TOTAL_HISTORICO=$(cat $DIR_02/lista_historico_a_ser_removido_"$DATA".csv | sed '1d' | wc -l)
TOTAL_ONUS_CACHE=$(cat $DIR_02/lista_onuscache_a_serem_removidas_"$DATA".csv | sed '1d' | wc -l)

# Escrevendo resultados...
echo "-> Consolidando resultados..."
echo "-> Lista de ONUs a serem removidas. (Total: $TOTAL_ONUS)"
echo "-> Lista de Historico a ser removido. (Total: $TOTAL_HISTORICO)"
echo "-> Lista de ONUs cache a serem removidas. (Total: $TOTAL_ONUS_CACHE)"

}

# Executando funcoes
gera_listas
limpar_dados_bd


DATA_EXE=$(date "+%d-%m-%Y_%H-%M-%S")
echo -e "\n----------------------------------------------------------"
echo -e "--> Fim da execucao: $DATA_EXE <--"
echo -e "----------------------------------------------------------"r