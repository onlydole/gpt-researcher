# Use a specific version tag for better reproducibility
FROM python:3.11.4-slim-bullseye AS base

# Combine RUN commands to reduce layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    firefox-esr \
    wget \
    build-essential \
    && wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
    && tar -xvzf geckodriver* \
    && chmod +x geckodriver \
    && mv geckodriver /usr/local/bin/ \
    && rm -rf /var/lib/apt/lists/* geckodriver*

ENV PIP_ROOT_USER_ACTION=ignore

WORKDIR /usr/src/app

# Copy only requirements.txt first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user
RUN useradd -ms /bin/bash gpt-researcher

# Copy the rest of the application
COPY --chown=gpt-researcher:gpt-researcher . .

# Switch to non-root user
USER gpt-researcher

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]