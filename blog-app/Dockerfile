# Use the official Python image with version 3.9
FROM python:3.9

# Set the working directory to /app
WORKDIR /app

# Copy the application code into the container
COPY app.py /app/
COPY admin.py /app/
COPY requirements.txt /app/
COPY templates /app/templates

# Install any required packages specified in requirements.txt
RUN pip install -r requirements.txt

# Set the default command to run the app
CMD ["python", "app.py"]
