# Use the official Python image with version 3.9
FROM python:3.9

# Set the working directory to /app
WORKDIR /app

# Copy the application code into the container
COPY app.py /app/
COPY admin.py /app/
COPY models.py /app/
COPY requirements.txt /app/
COPY templates /app/templates

# Install any required packages specified in requirements.txt
RUN pip install -r requirements.txt

# Expose port 80 for the Flask app
EXPOSE 80

# Set the default command to run the app
CMD ["python", "app.py"]
