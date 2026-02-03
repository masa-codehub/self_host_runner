# 1. ベースイメージ: ubuntu:latest
FROM ubuntu:latest

# ★ uv のインストール
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# ビルド時の対話防止とPython設定
ARG DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 2. 必須ツールと依存関係のインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gettext-base \
    git \
    gnupg \
    jq \
    libicu-dev \
    libssl-dev \
    lsb-release \
    procps \
    sudo \
    tar \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. GitHub CLI のインストール (wgetを使わずcurlで実行)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 4. Node.js のインストールと npm のアップデート
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# 5. Gemini CLI のインストール (preview指定)
RUN npm install -g @google/gemini-cli@preview

# 6. ランナー用のユーザー作成
RUN useradd -m runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 7. GitHub Actions Runner のダウンロードと展開
WORKDIR /home/runner
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//') \
    && curl -o actions-runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz" \
    && tar xzf ./actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner /home/runner

# 8. スクリプト類をコピーして権限設定
COPY --chown=runner:runner .build/entrypoint.sh .
RUN chmod u+x entrypoint.sh && sudo ./bin/installdependencies.sh

# 実行ユーザーに切り替え
USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]