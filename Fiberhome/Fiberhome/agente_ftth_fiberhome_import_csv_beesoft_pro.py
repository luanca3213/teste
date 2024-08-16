import os
import re
import sys
from datetime import datetime
from django.utils import timezone

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "beesoft.settings")
django.setup()

import csv
from ftth.models import Onu, OnuHistory, Olt

DATA = datetime.now()
print("----------------------------------------------------------")
print("--> Inicio da execucao: "+ str(DATA) +" <--")
print("----------------------------------------------------------\n")

def insere_bd (ip_olt):

    ip_olt = ip_address
    # try:
    olt = Olt.objects.get(ip=ip_olt)
    print('OLT ID:', olt.id)
    print('OLT Nome:', olt.nome)

    def import_data_from_csv(csv_file):
        with open(csv_file, 'r') as file:
            reader = csv.DictReader(file, delimiter=';')

            lista_dicionarios = []

            for row in reader:
                lista_dicionarios.append(row)

            seriais_contados = {}
            lista_resultante = []

            for dicionario in lista_dicionarios:
                serial = dicionario['serial']
                status = dicionario['status']

                # Verificar se o serial já foi encontrado antes
                if serial in seriais_contados:
                    seriais_contados[serial]['count'] += 1
                    if status != '1':
                        seriais_contados[serial]['status_2'] = True
                else:
                    seriais_contados[serial] = {'count': 1, 'status_2': False}

            for dicionario in lista_dicionarios:
                serial = dicionario['serial']
                status = dicionario['status']
                if seriais_contados[serial]['count'] == 1 or (seriais_contados[serial]['count'] > 1 and status == '1'):
                    lista_resultante.append(dicionario)

            #print(lista_resultante)


            for row in lista_resultante:
                #print(row)
                onuid = int(row['onuid'])
                pon = row['pon']
                serial = row['serial']
                onurx = float(row['onurx'])
                onutx = float(row['onutx'])
                model = row['model']
                status = row['status']
                now = timezone.now()

                try:
                    onu = Onu.objects.get(onuid=onuid, serial=serial, pon=pon, olt_fk=olt)
                    onu.model = model
                    onu.status = status
                    onu.timestamp = now
                    onu.version = '-'
                    onu.reason = '-'
                    onu.last_uptime = '01-01-1970 00:00:00'
                    onu.last_downtime = '01-01-1970 00:00:00'
                    onu.save()

                    # Salvar o histórico
                    OnuHistory.objects.create(
                        onu_fk=onu,
                        onurx=onurx,
                        onutx=onutx,
                        olt_fk=olt
                    )

                except Onu.DoesNotExist:
                    onu = Onu.objects.create(
                        pon=pon,
                        onuid=onuid,
                        serial=serial,
                        model=model,
                        status=status,
                        timestamp=now,
                        version='-',
                        reason='-',
                        last_uptime='01-01-1970 00:00:00',
                        last_downtime='01-01-1970 00:00:00',
                        olt_fk=olt
                    )

                    # Salvar o histórico
                    OnuHistory.objects.create(
                        onu_fk=onu,
                        onurx=onurx,
                        onutx=onutx,
                        olt_fk=olt
                    )

                # onu, created = Onu.objects.update_or_create(
                #     serial=serial,
                #     defaults={
                #         'pon': pon,
                #         'onuid': onuid,
                #         'model': model,
                #         'status': status,
                #         'timestamp': now,
                #         'version': '-',
                #         'reason': '-',
                #         'last_uptime': '01-01-1970 00:00:00',
                #         'last_downtime': '01-01-1970 00:00:00',
                #         'olt_fk': olt
                #     }
                # )
                #
                # # Atualizar os dados de Rx e Tx da ONU
                # onu.onurx = onurx
                # onu.onutx = onutx
                # onu.save()
                #
                # # Salvar o histórico
                # OnuHistory.objects.create(
                #     onu_fk=onu,
                #     onurx=onurx,
                #     onutx=onutx,
                #     olt_fk=olt
                # )
    # Windows
    #caminho = os.path.join('tmp','lista_final_onus_'+ ip_olt + '.csv')
    # Linux
    #caminho = os.path.join('opt','bee','beesoft','tmp','lista_final_onus_' + ip_olt + '.csv')
    caminho = '/opt/bee/tmp/fh/lista_final_onus_' + ip_olt + '.csv'

    print('Caminho:', caminho)

    # Execute a função para importar os dados do arquivo CSV
    import_data_from_csv(caminho)
    # except:
    #     print('--> Erro! Ip não encontrado na base de dados...')

ipv4_regex = r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

def validate_ipv4(ip_address):
    if re.match(ipv4_regex, ip_address):
        print("--> O IPv4 da OLT informado é válido...")
        insere_bd(ip_address)
    else:
        print("-->Erro! Por favor, verifique se o IPv4 da OLT foi informado corretamente...")

# Obtém o endereço IP da linha de comando
if len(sys.argv) > 1:
    ip_address = sys.argv[1]
    validate_ipv4(ip_address)
else:
    print("--> Erro! Por favor, insira um endereço IPv4 como argumento ao executar o script...")
    print('--> Ex: python agente_ftth_fiberhome.py 192.168.0.10')

DATA = datetime.now()
print("\n----------------------------------------------------------")
print("--> Fim da execucao: "+ str(DATA) +" <--")
print("----------------------------------------------------------")