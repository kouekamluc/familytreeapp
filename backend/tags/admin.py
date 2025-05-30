from django.contrib import admin
from .models import Tag

@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ('name', 'color', 'created_by', 'created_at')
    list_filter = ('created_by', 'created_at')
    search_fields = ('name', 'description')
    filter_horizontal = ('people', 'media_items')
    readonly_fields = ('created_at', 'updated_at')
    
    fieldsets = (
        (None, {
            'fields': ('name', 'description', 'color', 'created_by')
        }),
        ('Relations', {
            'fields': ('people', 'media_items')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
