import os
import subprocess
import sys

def run_command(command):
    subprocess.run(command, shell=True, check=True)

def setup_django_project():
    # Create Django project
    run_command('django-admin startproject familytree .')
    
    # Create apps
    run_command('python manage.py startapp users')
    run_command('python manage.py startapp family')
    run_command('python manage.py startapp media')
    
    # Create necessary directories
    os.makedirs('media/uploads', exist_ok=True)
    os.makedirs('static', exist_ok=True)
    
    print("Django project setup completed successfully!")

if __name__ == '__main__':
    setup_django_project() 