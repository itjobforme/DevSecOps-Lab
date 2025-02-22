# Use the official lightweight Python image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install required Python packages
RUN pip install Flask werkzeug

# Expose port 80 for the Flask app
EXPOSE 80

# Set the default environment
ENV FLASK_ENV=production

# Run the application
CMD ["python3", "app.py"]
