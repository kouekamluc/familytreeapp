from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, HeritageKey

class HeritageKeyInline(admin.TabularInline):
    model = HeritageKey
    extra = 1
    readonly_fields = ('usage_count', 'last_used_at', 'created_at')
    fields = ('key', 'name', 'role', 'is_active', 'expires_at', 'usage_count', 'last_used_at', 'created_at')

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'first_name', 'last_name', 'is_staff', 'get_heritage_key')
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
        return key.key if key else '-'
    get_heritage_key.short_description = 'Primary Heritage Key'


@admin.register(HeritageKey)
class HeritageKeyAdmin(admin.ModelAdmin):
    list_display = ('key', 'user', 'name', 'role', 'is_active', 'usage_count', 'last_used_at', 'created_at')
    list_filter = ('role', 'is_active', 'created_at')
    search_fields = ('key', 'name', 'user__username', 'user__email', 'user__first_name', 'user__last_name')
    readonly_fields = ('usage_count', 'last_used_at', 'created_at', 'updated_at')
    actions = ['generate_new_keys_for_selected', 'deactivate_keys']

    def generate_new_keys_for_selected(self, request, queryset):
        for item in queryset:
            item.key = HeritageKey.generate_royal_key_string()
            item.save()
        self.message_user(request, f"Regenerated keys for {queryset.count()} records.")
    generate_new_keys_for_selected.short_description = "Regenerate royal key string"

    def deactivate_keys(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f"Deactivated {queryset.count()} keys.")
    deactivate_keys.short_description = "Deactivate selected keys"

