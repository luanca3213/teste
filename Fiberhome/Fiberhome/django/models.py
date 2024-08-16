# Create your models here.

from django.db import models

from django.contrib.auth.models import User
from cryptography.fernet import Fernet
from django.conf import settings

class Fabricante(models.Model):
    nome = models.CharField(max_length=200)

    class Meta:
        verbose_name_plural = "Fabricantes"

    def __str__(self):
        return str(self.nome)

class Modelo(models.Model):
    nome = models.CharField(max_length=200)
    fabricante_fk = models.ForeignKey(Fabricante, on_delete=models.CASCADE)

    class Meta:
        verbose_name_plural = "Modelos"

    def __str__(self):
        return str(self.nome)

class Cliente(models.Model):
    nome = models.CharField(max_length=200)
    cpf_cnpj = models.CharField(max_length=200)
    habilitado = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Clientes"

    def __str__(self):
        return str(self.nome)

class Olt(models.Model):
    ip = models.GenericIPAddressField(max_length=100)
    nome = models.CharField(max_length=200)
    usuario = models.CharField(max_length=100)
    senha = models.CharField(max_length=200)
    porta_ssh = models.IntegerField(default=22)
    porta_telnet = models.IntegerField(default=23)
    community_snmp = models.CharField(max_length=100, default='public')
    porta_snmp = models.IntegerField(default=161)
    modelo_fk = models.ForeignKey(Modelo, on_delete=models.CASCADE, default='C600')
    cliente_fk = models.ForeignKey(Cliente, on_delete=models.CASCADE, null=True, blank=True)
    usuario_fk = models.ManyToManyField(User)
    habilitado = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Olts"

    def __str__(self):
        return str(self.nome)

    def encrypt_password(self):
        key = settings.FERNET_KEY.encode()
        f = Fernet(key)
        return f.encrypt(self.senha).decode()

    def decrypt_password(self):
        key = settings.FERNET_KEY.encode()
        f = Fernet(key)
        return f.decrypt(self.senha).decode()

    def save(self, *args, **kwargs):
        self.senha = self.senha
        super().save(*args, **kwargs)

class Onu(models.Model):
    onuid = models.IntegerField(null=True, blank=True)
    pon = models.CharField(max_length=200, null=True, blank=True)
    serial = models.CharField(max_length=200, null=True, blank=True)
    description = models.CharField(max_length=200, null=True, blank=True)
    name = models.CharField(max_length=200, null=True, blank=True)
    cto = models.CharField(max_length=200, null=True, blank=True)
    vlan = models.IntegerField(null=True, blank=True)
    model = models.CharField(max_length=200, null=True, blank=True)
    version = models.CharField(max_length=200, null=True, blank=True)
    status = models.CharField(max_length=200, null=True, blank=True)
    distance = models.CharField(max_length=200, null=True, blank=True)
    temperature = models.CharField(max_length=200, null=True, blank=True)
    uptime = models.CharField(max_length=200, null=True, blank=True)
    last_uptime = models.CharField(max_length=200, null=True, blank=True)
    last_downtime = models.CharField(max_length=200, null=True, blank=True)
    reason = models.CharField(max_length=200, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    olt_fk = models.ForeignKey(Olt, null=True, on_delete=models.CASCADE)

    class Meta:
        verbose_name_plural = "Onus"

    def __str__(self):
        return str(self.serial)

class OnuHistory(models.Model):
    onurx = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    onutx = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    oltrx = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    onu_fk = models.ForeignKey(Onu, on_delete=models.CASCADE)
    olt_fk = models.ForeignKey(Olt, on_delete=models.CASCADE)

    class Meta:
        verbose_name_plural = "Historico de Sinal"

    def __str__(self):
        return str(self.onu_fk)

class OnuCache(models.Model):
    onuid = models.IntegerField(null=True, blank=True)
    sn = models.CharField(max_length=200, null=True, blank=True)
    pon = models.CharField(max_length=200, null=True, blank=True)
    status = models.CharField(max_length=200, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    olt_fk = models.ForeignKey(Olt, null=True, on_delete=models.CASCADE)

    class Meta:
        verbose_name_plural = "OnusCache"

    def __str__(self):
        return self.sn