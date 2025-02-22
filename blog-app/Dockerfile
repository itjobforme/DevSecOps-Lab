# Dockerfile
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Copy the app.py file into the container
COPY app.py /app/app.py

# Install Flask and Werkzeug
RUN pip install flask werkzeug

# Expose port 80 for the application
EXPOSE 80

# Run the Flask app
CMD ["python", "app.py"]
