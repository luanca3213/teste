#!/bin/bash

#Desnvolvido por: Bee Solutions
#Autor: Fernando Almondes
#Data: 15/05/2023

DATA=$(date "+%d-%m-%Y_%H-%M-%S")
echo "Ultima execucao: $DATA"

IP="$1"
COMMUNITY="$2"

#Lista de ONUs por slot: 1.3.6.1.4.1.5875.800.3.10.1.1.2
#Lista de ONUs por porta: 1.3.6.1.4.1.5875.800.3.10.1.1.3
#Lista de ONUs por status: 1.3.6.1.4.1.5875.800.3.10.1.1.11
#Lista de ONUs por onuid: 1.3.6.1.4.1.5875.800.3.10.1.1.4

# Gerando lista atualizada
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.2 > /var/tmp/zabbix/fh/lista_slots_$IP.txt
sleep 5
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.3 > /var/tmp/zabbix/fh/lista_pons_$IP.txt
sleep 5
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.11 > /var/tmp/zabbix/fh/lista_status_$IP.txt
sleep 5
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.4 > /var/tmp/zabbix/fh/lista_onuid_$IP.txt
sleep 5
snmpwalk -On -v2c -c "$COMMUNITY" "$IP" .1.3.6.1.4.1.5875.800.3.10.1.1.10 > /var/tmp/zabbix/fh/lista_sn_$IP.txt

# Criando listas
lista_slots=$(cat /var/tmp/zabbix/fh/lista_slots_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.2.' '{print $2}' | awk '{print $1,$4}')
lista_pons=$(cat /var/tmp/zabbix/fh/lista_pons_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.3.' '{print $2}' | awk '{print $1,$4}')
lista_status=$(cat /var/tmp/zabbix/fh/lista_status_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.11.' '{print $2}' | awk '{print $1,$4}')
lista_onuid=$(cat /var/tmp/zabbix/fh/lista_onuid_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.4.' '{print $2}' | awk '{print $1,$4}')
lista_sn=$(cat /var/tmp/zabbix/fh/lista_sn_$IP.txt | awk -F '.1.3.6.1.4.1.5875.800.3.10.1.1.10.' '{print $2}' | sed 's/"//g' | awk '{print $1,$4}')

# Criando lista final
echo "" > /var/tmp/zabbix/fh/lista_final_$IP.txt

#Debug aqui
#echo "$lista_slots"
#echo "$lista_pons"
#echo "$lista_status"
#echo "$lista_onuid"
#echo "$lista_sn"

# Lendo listas e criando lista unica
while read id slot
do

porta=$(grep "^$id " <<< "$lista_pons" | cut -d " " -f 2)
status=$(grep "^$id " <<< "$lista_status" | cut -d " " -f 2)
onuid=$(grep "^$id " <<< "$lista_onuid" | cut -d " " -f 2)
sn=$(grep "^$id " <<< "$lista_sn" | cut -d " " -f 2)

echo "$onuid $slot/$porta $status $sn" >> /var/tmp/zabbix/fh/lista_final_$IP.txt

done <<< "$lista_slots"

# Criando lista Cache

echo "onuid;pon;status;sn" > "/opt/bee/tmp/fh/lista_final_onus_cache_$IP.csv"

cat /var/tmp/zabbix/fh/lista_final_$IP.txt | awk NF | awk '{print $1";"$2";"$3";"$4}' >> "/opt/bee/tmp/fh/lista_final_onus_cache_$IP.csv"


############### ADICIONANDO VALIDACAO DO CSV ##########################

csv_file="/opt/bee/tmp/fh/lista_final_onus_cache_$IP.csv"
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
expected_columns=("onuid" "pon" "status" "sn")
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
  validate_status "${fields[2]}"

done < <(tail -n +2 "$csv_file")

if [ "$errors" -gt 0 ]; then
  echo "Foram encontrados erros no arquivo CSV."
  exit 1
fi

echo "Arquivo CSV válido."

/opt/bee/venv/bin/python /opt/bee/agente_ftth_fiberhome_cache.py "$IP"