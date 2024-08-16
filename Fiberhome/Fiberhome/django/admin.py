from django.contrib import admin

from django.db import models
from django import forms

from ftth.models import Cliente, Fabricante, Modelo, Olt, Onu, OnuHistory, OnuCache
from django.db.models import Q

from ftth.forms import OltAdminForm

# Acoes
import csv
from django.http import HttpResponse

# Register your models here.

admin.site.site_title = 'Admin Beesoft (Bee Solutions)'

class FabricanteAdmin(admin.ModelAdmin):
    list_display = ['nome']
admin.site.register(Fabricante, FabricanteAdmin)

class ModeloAdmin(admin.ModelAdmin):
    list_display = ['nome','fabricante_fk']
admin.site.register(Modelo, ModeloAdmin)

class ClienteAdmin(admin.ModelAdmin):
    list_display = ['nome','cpf_cnpj','habilitado']
admin.site.register(Cliente, ClienteAdmin)

class OltAdmin(admin.ModelAdmin):
    list_display = ['ip','nome','modelo_nome','fabricante_nome','usuarios_olt','cliente_fk','habilitado']
    list_filter = ('modelo_fk', 'modelo_fk__fabricante_fk', 'cliente_fk','habilitado')
    search_fields = ['nome', 'modelo_fk__nome', 'modelo_fk__fabricante_fk__nome', 'cliente_fk__nome']

    def modelo_nome(self, obj):
        return obj.modelo_fk.nome
    modelo_nome.short_description = 'Modelo'

    def fabricante_nome(self, obj):
        return obj.modelo_fk.fabricante_fk
    fabricante_nome.short_description = 'Fabricante'

    def usuarios_olt(self, obj):
        return ", ".join([str(p) for p in obj.usuario_fk.all()])

    usuarios_olt.short_description = "Usuarios"

    form = OltAdminForm

admin.site.register(Olt, OltAdmin)

class ExportarCSVActionMixin:
    def exportar_csv(self, request, queryset):
        meta = queryset.model._meta
        field_names = [field.name for field in meta.fields]
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename={meta}.csv'
        writer = csv.writer(response, delimiter=';') # Adicione o separador aqui
        writer.writerow(field_names)
        for obj in queryset:
            writer.writerow([getattr(obj, field) for field in field_names])
        return response
    exportar_csv.short_description = 'Exportar para CSV'

class OnuAdmin(ExportarCSVActionMixin, admin.ModelAdmin):
    list_display = ['olt_fk','onuid','pon','serial','description','name','cto','vlan','model','version','status','distance','uptime','reason','timestamp']
    list_filter = ('olt_fk', 'status', 'reason', 'model','version','vlan')
    search_fields = ['onuid', 'pon', 'serial', 'name', 'vlan', 'model','version', 'status','timestamp']
    #actions = ['exportar_csv','exportar_pdf']
    actions = ['exportar_csv']
admin.site.register(Onu, OnuAdmin)

class OnuHistoryAdmin(ExportarCSVActionMixin, admin.ModelAdmin):
    list_display = ['onurx','onutx','oltrx','timestamp','onu_fk','olt_fk']
    list_filter = ['olt_fk']
    search_fields = ['onurx','onu_fk__serial']
    actions = ['exportar_csv']

admin.site.register(OnuHistory, OnuHistoryAdmin)

class OnuCacheAdmin(admin.ModelAdmin):
    list_display = [field.name for field in OnuCache._meta.get_fields()]
    list_filter = ('olt_fk', 'status')
    search_fields = ['sn']
admin.site.register(OnuCache, OnuCacheAdmin)