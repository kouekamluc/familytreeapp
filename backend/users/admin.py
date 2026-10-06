from django.contrib import admin
from django import forms
from django.contrib.auth.admin import UserAdmin
from .models import User, HeritageKey, AccountDeletionRequest

class HeritageKeyInline(admin.TabularInline):
    model = HeritageKey
    extra = 0
    def has_add_permission(self, request, obj=None):
        return False
    readonly_fields = ('key', 'usage_count', 'last_used_at', 'created_at')
    fields = ('name', 'role', 'is_active', 'expires_at', 'usage_count', 'last_used_at', 'created_at')

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'first_name', 'last_name', 'is_staff', 'email_verified')
    list_filter = ('is_staff', 'is_superuser', 'is_active')
    search_fields = ('email', 'username', 'first_name', 'last_name')
    ordering = ('email',)
    inlines = [HeritageKeyInline]
    
    fieldsets = (
        (None, {'fields': ('email', 'username', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'bio', 'profile_picture', 'date_of_birth', 'phone_number')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'username', 'password1', 'password2'),
        }),
    )

    def get_heritage_key(self, obj):
        key = obj.heritage_keys.filter(is_active=True).first()
        return f'Key #{key.pk}' if key else '-'
    get_heritage_key.short_description = 'Primary Heritage Key'


@admin.register(HeritageKey)
class HeritageKeyAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'name', 'role', 'is_active', 'usage_count', 'last_used_at', 'created_at')
    list_filter = ('role', 'is_active', 'created_at')
    search_fields = ('name', 'user__username', 'user__email', 'user__first_name', 'user__last_name')
    readonly_fields = ('key', 'usage_count', 'last_used_at', 'created_at', 'updated_at')
    actions = ['deactivate_keys']
    def has_add_permission(self, request):
        return False

    def deactivate_keys(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f"Deactivated {queryset.count()} keys.")
    deactivate_keys.short_description = "Deactivate selected keys"



class DeletionReviewForm(forms.ModelForm):
    class Meta:
        model = AccountDeletionRequest
        fields = '__all__'
    def clean(self):
        data = super().clean()
        if data.get('status') == 'COMPLETED' and self.instance.user_id:
            from django.forms import ValidationError
            raise ValidationError('Complete the reviewed account/data deletion before closing its request.')
        return data


@admin.register(AccountDeletionRequest)
class DeletionRequestAdmin(admin.ModelAdmin):
    form = DeletionReviewForm
    list_display = ('id', 'user', 'status', 'requested_at', 'updated_at')
    list_filter = ('status',)
    readonly_fields = ('user', 'requested_at', 'updated_at')
    def has_add_permission(self, request):
        return False
