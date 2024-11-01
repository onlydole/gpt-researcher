# Stage 1: Build environment
FROM python:3.12-slim-bullseye AS builder

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1 \
  PIP_NO_CACHE_DIR=1

WORKDIR /build

# Install build dependencies and browsers in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
  chromium \
  chromium-driver \
  firefox-esr \
  wget \
  build-essential \
  && wget -q https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
  && tar -xzf geckodriver-v0.33.0-linux64.tar.gz \
  && mv geckodriver /usr/local/bin/ \
  && rm geckodriver-v0.33.0-linux64.tar.gz \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Copy only requirements files first to leverage cache
COPY requirements.txt .
COPY multi_agents/requirements.txt ./multi_agents/

# Install Python dependencies
RUN pip install --upgrade pip && \
  pip install -r requirements.txt -r multi_agents/requirements.txt

# Stage 2: Final runtime image
FROM python:3.12-slim-bullseye

# Set runtime environment variables
ENV PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1

# Create non-root user
RUN useradd -ms /bin/bash appuser

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  chromium \
  chromium-driver \
  firefox-esr \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Copy geckodriver and Python packages from builder
COPY --from=builder /usr/local/bin/geckodriver /usr/local/bin/
COPY --from=builder /usr/local/lib/python3.12/site-packages/ /usr/local/lib/python3.12/site-packages/

WORKDIR /app

# Create outputs directory and set permissions
RUN mkdir outputs && \
  chown -R appuser:appuser /app && \
  chmod -R 755 /app

# Copy application code
COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 8000

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]