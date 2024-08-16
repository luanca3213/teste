import os
import re
import sys
from datetime import datetime
from django.utils import timezone

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "beesoft.settings")
django.setup()

import csv
from ftth.models import OnuCache, Olt

DATA = datetime.now()
print("----------------------------------------------------------")
print("--> Inicio da execucao: "+ str(DATA) +" <--")
print("----------------------------------------------------------\n")

def insere_bd (ip_olt):

    ip_olt = ip_address

    olt = Olt.objects.get(ip=ip_olt)
    print('OLT ID:', olt.id)
    print('OLT Nome:', olt.nome)

    def import_data_from_csv(csv_file):

        # Carregar todas as ONUs atuais do banco de dados | Faco isso pra excluir as ONUs que nao aparecem mais na lista
        #current_onus = OnuCache.objects.filter(olt_fk=olt)

        # Criar uma lista para armazenar as ONUs do CSV
        #csv_onus = []

        with open(csv_file, 'r') as file:
            reader = csv.DictReader(file, delimiter=';')

            for row in reader:
                #print(row)
                onuid = int(row['onuid'])
                pon = row['pon']
                status = row['status']
                sn = row['sn']
                now = timezone.now()

                # Adicionar informacoes da ONU do CSV a lista
                #csv_onus.append((onuid, sn, pon, olt.id))

                try:
                    onucache = OnuCache.objects.get(onuid=onuid, sn=sn, pon=pon, olt_fk_id=olt.id)
                    onucache.status = status
                    onucache.timestamp = now
                    onucache.save()

                except OnuCache.DoesNotExist:
                    onucache = OnuCache.objects.create(
                    sn=sn,
                    onuid=onuid,
                    pon=pon,
                    status=status,
                    timestamp=now,
                    olt_fk_id=olt.id
                    )

        # Identificar as ONUs que não estão mais no CSV e excluí-las
        #for onu in current_onus:
        #    if (onu.onuid, onu.sn, onu.pon, onu.olt_fk.id) not in csv_onus:
        #        onu.delete()

                # onucache, created = OnuCache.objects.update_or_create(
                #     sn=sn,
                #     defaults={
                #         'sn': sn,
                #         'onuid': onuid,
                #         'pon': pon,
                #         'status': status,
                #         'datetime': now,
                #         'olt_fk_id': olt.id
                #     }
                # )
                # onucache.save()

    # Execute a função para importar os dados do arquivo CSV
    import_data_from_csv('/opt/bee/tmp/fh/lista_final_onus_cache_'+ip_olt+'.csv')
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