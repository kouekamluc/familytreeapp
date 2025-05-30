# Family Tree Web Application

A comprehensive web application for building and managing family trees with interactive visualization features.

## Backend Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
Create a `.env` file in the root directory with the following variables:
```
DEBUG=True
SECRET_KEY=your-secret-key
DATABASE_URL=postgresql://user:password@localhost:5432/familytree
```

4. Run migrations:
```bash
python manage.py migrate
```

5. Create a superuser:
```bash
python manage.py createsuperuser
```

6. Run the development server:
```bash
python manage.py runserver
```

## API Documentation

The API documentation will be available at `/api/docs/` when the server is running.

## Features

- Interactive family tree visualization
- Comprehensive data management
- User-friendly interface
- Data import/export capabilities
- Media management
- User authentication and authorization
- RESTful API endpoints 