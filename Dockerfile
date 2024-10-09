FROM python:3.11.4-slim-bullseye AS install-browser

# Combine RUN commands to reduce layers and clean up after installations
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  chromium \
  chromium-driver \
  firefox-esr \
  wget && \
  wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz && \
  tar -xvzf geckodriver* && \
  chmod +x geckodriver && \
  mv geckodriver /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* geckodriver*  # Clean up

# Install build tools
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential && \
  rm -rf /var/lib/apt/lists/*

FROM install-browser AS gpt-researcher-install

ENV PIP_ROOT_USER_ACTION=ignore

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

COPY ./requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt  # Use --no-cache-dir to reduce size

COPY ./multi_agents/requirements.txt ./multi_agents/requirements.txt
RUN pip install --no-cache-dir -r multi_agents/requirements.txt  # Use --no-cache-dir to reduce size

FROM gpt-researcher-install AS gpt-researcher

ARG OPENAI_API_KEY
ARG TAVILY_API_KEY

ENV OPENAI_API_KEY=${OPENAI_API_KEY}
ENV TAVILY_API_KEY=${TAVILY_API_KEY}

RUN useradd -ms /bin/bash gpt-researcher && \
  chown -R gpt-researcher:gpt-researcher /usr/src/app

USER gpt-researcher

COPY --chown=gpt-researcher:gpt-researcher ./ ./

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]