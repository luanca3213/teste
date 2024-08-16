
from django import forms

from cryptography.fernet import Fernet
from django.conf import settings

from ftth.models import Olt

class OltAdminForm(forms.ModelForm):
    senha = forms.CharField(widget=forms.PasswordInput(attrs={'class': 'form-control', 'placeholder': 'Senha', 'required': True}))

    class Meta:
        model = Olt
        fields = ['ip','nome','usuario','senha','porta_ssh','porta_telnet','community_snmp','porta_snmp','modelo_fk','usuario_fk','cliente_fk','habilitado']

    def clean_senha(self):
        key = settings.FERNET_KEY.encode()
        f = Fernet(key)
        return f.encrypt(self.cleaned_data['senha'].encode()).decode()