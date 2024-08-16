#!/bin/bash

#Desnvolvido por: Bee Solutions
#Autor: Fernando Almonde
#Data: 15/05/2023

DATA=$(date "+%d-%m-%Y_%H-%M-%S")
echo "----------------------------------------------------------"
echo -e "\n--> Inicio da execucao: $DATA <--\n"
echo "----------------------------------------------------------"

IP="$1"
COMMUNITY="$2"

#Lista de ONUs por Slot: 1.3.6.1.4.1.5875.800.3.10.1.1.2
#Lista de ONUs por Porta: 1.3.6.1.4.1.5875.800.3.10.1.1.3

# Monitoramento individual (Somente as ONUs Onlines com status 1 sao apresentadas)
#Lista de ONUs ONUID: 1.3.6.1.4.1.5875.800.3.9.3.3.1.2
#Lista de ONUs SN: 1.3.6.1.4.1.5875.800.3.10.1.1.10
#Lista de ONUs RX: 1.3.6.1.4.1.5875.800.3.9.3.3.1.6
#Lista de ONUs TX: 1.3.6.1.4.1.5875.800.3.9.3.3.1.7
#Lista de ONUs Modelo: 1.3.6.1.4.1.5875.800.3.10.1.1.37
#Lista de ONUs por Status: 1.3.6.1.4.1.5875.800.3.10.1.1.11

gera_listas () {

# Gerando lista atualizada
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.9.3.3.1.2 > /opt/bee/tmp/fh/lista_onu_id_$IP.txt
sleep 10
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.10 > /opt/bee/tmp/fh/lista_onu_sn_$IP.txt
sleep 10
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.9.3.3.1.6 > /opt/bee/tmp/fh/lista_onu_rx_$IP.txt
sleep 10
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.9.3.3.1.7 > /opt/bee/tmp/fh/lista_onu_tx_$IP.txt
sleep 10
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.37 > /opt/bee/tmp/fh/lista_onu_modelo_$IP.txt
sleep 10
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.11 > /opt/bee/tmp/fh/lista_onu_status_$IP.txt

}


ler_listas () {

echo "Criando listas..."
# Criando listas
lista_onu_id=$(cat /opt/bee/tmp/fh/lista_onu_id_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.9.3.3.1.2.' '{print $2}' | sed 's/"//g' | sed 's/PON /PON-/g' | awk '{print $1,$4}' | sed 's/[^[:print:]]//g')
lista_onu_sn=$(cat /opt/bee/tmp/fh/lista_onu_sn_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.10.' '{print $2}' | sed 's/"//g' | awk '{print $1,$4}')
lista_onu_rx=$(cat /opt/bee/tmp/fh/lista_onu_rx_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.9.3.3.1.6.' '{print $2}' | sed 's/"//g' | awk '{print $1,$4}')
lista_onu_tx=$(cat /opt/bee/tmp/fh/lista_onu_tx_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.9.3.3.1.7.' '{print $2}' | sed 's/"//g' | awk '{print $1,$4}')
lista_onu_modelo=$(cat /opt/bee/tmp/fh/lista_onu_modelo_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.37.' '{print $2}' | sed 's/"//g' | awk '{print $1,$4}')
lista_onu_status=$(cat /opt/bee/tmp/fh/lista_onu_status_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.11.' '{print $2}' | sed 's/"//g' | awk '{print $1,$4}' | sed 's/[^[:print:]]//g')

# Criando lista auxiliar
echo > /opt/bee/tmp/fh/lista_final_onus_"$IP"_aux.csv

# Lendo listas e criando lista unica
while read id status
do

onu_id=$(grep "^$id " <<< "$lista_onu_id" | cut -d " " -f 2)
onu_sn=$(grep "^$id " <<< "$lista_onu_sn" | cut -d " " -f 2)
onu_rx=$(grep "^$id " <<< "$lista_onu_rx" | cut -d " " -f 2)
onu_tx=$(grep "^$id " <<< "$lista_onu_tx" | cut -d " " -f 2)
onu_modelo=$(grep "^$id " <<< "$lista_onu_modelo" | cut -d " " -f 2)


  if [ -z "$onu_id" ]; then
    onu_id="0"
  fi

  if [ -z "$onu_sn" ]; then
    onu_sn="-"
  fi

  if [ -z "$onu_rx" ]; then
    onu_rx="-"
  fi

  if [ -z "$onu_tx" ]; then
    onu_tx="-"
  fi

  if [ -z "$onu_modelo" ]; then
    onu_modelo="-"
  fi


echo "$id;$onu_id;$onu_sn;$onu_rx;$onu_tx;$onu_modelo;$status" | awk -F ";" '{
printf "%s;%s;%s;%.2f;%.2f;%s;%d\n", $1, $2, $3, $4/100, $5/100, $6, $7}' >> /opt/bee/tmp/fh/lista_final_onus_"$IP"_aux.csv

done <<< "$lista_onu_status"

#cat /opt/bee/tmp/fh/lista_final_onus_$IP.csv

#Fazendo ajuste
echo "Iniciando ajuste..."
lista_onus_geral=$(cat /var/tmp/zabbix/fh/lista_final_$IP.txt | awk NF)
lista_onus_final=$(cat /opt/bee/tmp/fh/lista_final_onus_"$IP"_aux.csv | awk NF)

while IFS=' ' read -r id pon status serial; do
  lista_onus_final=$(echo "$lista_onus_final" | awk -v id="$id" -v pon="$pon" -v serial="$serial" -F ';' '{if ($3 == serial) {$1 = id; $2 = pon;} } 1')
done <<< "$lista_onus_geral"

# Criando a lista final
echo "onuid;pon;serial;onurx;onutx;model;status" > /opt/bee/tmp/fh/lista_final_onus_$IP.csv

echo "$lista_onus_final" | grep -v "PON-" | awk '{print $1";"$2";"$3";"$4";"$5";"$6";"$7}' >> /opt/bee/tmp/fh/lista_final_onus_$IP.csv

echo "Imprimindo resultado..."
cat /opt/bee/tmp/fh/lista_final_onus_$IP.csv

}

insere_bd () {

echo "Inserindo dados no BD"

/opt/bee/venv/bin/python /opt/bee/agente_ftth_fiberhome_import_csv_beesoft_pro.py "$IP"

}

validando_csv() {

############### ADICIONANDO VALIDACAO DO CSV ##########################

csv_file="/opt/bee/tmp/fh/lista_final_onus_$IP.csv"
errors=0

# Função para validar o formato de PON
validate_pon() {
  if [[ ! $1 =~ ^[0-9]+/[0-9]+$ ]]; then
    echo "Formato PON inválido: $1"
    errors=$((errors + 1))
  fi
}

# Função para validar o status
validate_status() {
  if [[ ! $1 =~ ^[0-9]$ ]]; then
    echo "Status inválido: $1"
    errors=$((errors + 1))
  fi
}

# Verifica se o arquivo CSV existe
if [ ! -f "$csv_file" ]; then
  echo "Arquivo CSV não encontrado."
  exit 1
fi

# Verifica se as colunas estão presentes
expected_columns=("onuid" "pon" "serial" "onurx" "onutx" "model" "status")
header=$(head -n 1 "$csv_file")
IFS=';' read -ra columns <<< "$header"
for col in "${expected_columns[@]}"; do
  if [[ ! " ${columns[@]} " =~ " $col " ]]; then
    echo "Coluna '$col' não encontrada no arquivo CSV."
    exit 1
  fi
done

# Verifica os dados das linhas
while IFS=';' read -ra fields; do
  if [ "${#fields[@]}" -ne "${#expected_columns[@]}" ]; then
    echo "Linha com número incorreto de campos: ${fields[*]}"
    errors=$((errors + 1))
  fi

  if [ -z "${fields[3]}" ]; then
    echo "Serial em branco: ${fields[*]}"
    errors=$((errors + 1))
  fi

  validate_pon "${fields[1]}"
  validate_status "${fields[6]}"

done < <(tail -n +2 "$csv_file")

if [ "$errors" -gt 0 ]; then
  echo "Foram encontrados erros no arquivo CSV."
  exit 1
fi

echo "Arquivo CSV válido."

}

ipv4_regex='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

# Validando argumentos
if [[ ! -z "$1"  ]] && [[ ! -z "$2" ]] && [[ "$1" =~ $ipv4_regex ]]; then
    echo "Parametros passados corretamente..."
    echo "IP: $1"
    echo "COMMUNITY: $2"
    echo "Executando verificacao, por favor aguarde..."
    gera_listas
    ler_listas
    validando_csv
    insere_bd

else
    echo "Erro! Por favor, informe o IP e COMMUNITY SNMP da OLT ou verifique se o IP digitado esta correto..."
    echo "Ex: ./contador_onu.sh 192.168.0.10 public"
fi

DATA=$(date "+%d-%m-%Y_%H-%M-%S")
echo "----------------------------------------------------------"
echo -e "\n--> Fim da execucao: $DATA <--\n"
echo "----------------------------------------------------------"