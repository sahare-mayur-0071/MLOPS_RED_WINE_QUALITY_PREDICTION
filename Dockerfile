FROM python:3.8.19-slim-bullseye

# Set environment variables to prevent Python from writing .pyc files
# and to ensure logs are immediately visible
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Create a non-root user and group for better security
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Copy requirements first to leverage Docker cache for pip install
COPY requirements.txt .

# Copy setup.py and required files for `-e .` (editable install)
COPY setup.py .
COPY README.md .
COPY src/ src/

# Install dependencies with --no-cache-dir to reduce layer size
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the remaining project files with correct ownership
COPY --chown=appuser:appgroup . .

# Ensure the non-root user has write permissions for app directory (e.g., for ML models)
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose port (Render will assign the actual port)
EXPOSE 8080

# Add HEALTHCHECK to monitor application status
HEALTHCHECK --interval=30s --timeout=15s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/')" || exit 1

# Use ENTRYPOINT and CMD for a lighter, more standard execution format
ENTRYPOINT ["gunicorn"]
CMD ["--bind", "0.0.0.0:8080", "app:app"]