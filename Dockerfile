FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    wget gnupg2 unzip curl \
    && mkdir -p /etc/apt/keyrings \
    && wget -q -O /etc/apt/keyrings/google-chrome.asc https://dl.google.com/linux/linux_signing_key.pub \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

RUN CHROME_VERSION=$(google-chrome --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') \
    && DRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}.0/linux64/chromedriver-linux64.zip" \
    && wget -q "$DRIVER_URL" -O /tmp/chromedriver.zip || true \
    && if [ -f /tmp/chromedriver.zip ]; then \
         unzip /tmp/chromedriver.zip -d /tmp/ && \
         mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/ && \
         chmod +x /usr/local/bin/chromedriver; \
       fi \
    && rm -rf /tmp/chromedriver*

ENV CHROME_BIN=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 10000

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:10000", "--timeout", "300", "--workers", "1", "--threads", "4"]
