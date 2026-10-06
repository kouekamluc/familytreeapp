from django import forms
from django.contrib.auth import authenticate
from django.shortcuts import render
from django.views.decorators.csrf import csrf_protect
from django.core.cache import cache
from .models import AccountDeletionRequest


class DeletionForm(forms.Form):
    username = forms.CharField(max_length=150)
    password = forms.CharField(widget=forms.PasswordInput, max_length=512)


@csrf_protect
def deletion_resource(request):
    form = DeletionForm(request.POST or None)
    submitted = False
    if request.method == 'POST' and form.is_valid():
        # Same response for unknown credentials; bound guessing per source address.
        scope = 'deletion-web:' + request.META.get('REMOTE_ADDR', '')
        attempts = cache.get(scope, 0)
        if attempts < 6:
            cache.set(scope, attempts + 1, 60)
            user = authenticate(request, username=form.cleaned_data['username'], password=form.cleaned_data['password'])
            if user:
                deletion, _ = AccountDeletionRequest.objects.get_or_create(user=user)
                if deletion.status == 'CANCELLED':
                    deletion.status = 'PENDING'
                    deletion.save(update_fields=['status', 'updated_at'])
        submitted = True
    return render(request, 'users/account_deletion.html', {'form': form, 'submitted': submitted})
