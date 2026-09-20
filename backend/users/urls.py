from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    path('register/', views.RegisterView.as_view(), name='register'),
    path('user/', views.UserView.as_view(), name='user'),
    path('me/', views.UserView.as_view(), name='user_me'),
    
    # Heritage Key Authentication & Management
    path('heritage-key/login/', views.HeritageKeyLoginView.as_view(), name='heritage_key_login'),
    path('heritage-key-login/', views.HeritageKeyLoginView.as_view(), name='heritage_key_login_alias'),
    path('heritage-key/me/', views.HeritageKeyMeView.as_view(), name='heritage_key_me'),
    path('heritage-key/generate/', views.HeritageKeyGenerateView.as_view(), name='heritage_key_generate'),
    path('heritage-key/revoke/', views.HeritageKeyRevokeView.as_view(), name='heritage_key_revoke'),
]
 