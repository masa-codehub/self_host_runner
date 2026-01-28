# --- 最終的な実行イメージ (Ubuntuベースで一本化) ---
FROM ubuntu:latest

# ビルド時のみ対話型プロンプトを無効化
ARG DEBIAN_FRONTEND=noninteractive

# 1. 基本ツールと依存関係のインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        curl \
        git \
        jq \
        sudo \
        gnupg \
        ca-certificates \
        lsb-release \
        procps \
        tmux \
        libicu-dev \
        tar \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        awk \
    && rm -rf /var/lib/apt/lists/*

# 2. Python のインストール (PPA から最新バージョンを動的に検出してインストール)
RUN add-apt-repository ppa:deadsnakes/ppa -y && apt-get update \
    && LATEST_PY=$(apt-cache search '^python3\.[0-9]+$' | awk '{print $1}' | sort -V | tail -n 1) \
    && echo "Installing latest detected Python: ${LATEST_PY}" \
    && apt-get install -y --no-install-recommends \
        ${LATEST_PY} ${LATEST_PY}-dev ${LATEST_PY}-venv python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/${LATEST_PY} 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/${LATEST_PY} 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# CI環境での pip install エラー (PEP 668) を回避するための設定
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# 3. Node.js のインストール (NodeSource Current: 常に最新版)
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# 4. GitHub CLI のインストール
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# 5. Google Cloud CLI (gcloud) のインストール
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# 6. Gemini CLI のインストール (本体はグローバルに)
RUN npm install -g @google/gemini-cli@preview

# 7. ランナー用のユーザー作成
RUN useradd -m runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 8. GitHub Actions Runner のダウンロードと展開
WORKDIR /home/runner
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//') \
    && curl -o actions-runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz" \
    && tar xzf ./actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner /home/runner

# 9. スクリプト類をコピーして権限設定
COPY --chown=runner:runner .build/entrypoint.sh .
RUN chmod u+x entrypoint.sh && sudo ./bin/installdependencies.sh

# 実行ユーザーに切り替えてから拡張機能をインストール
USER runner

# Gemini 拡張機能を runner ユーザーのホームディレクトリにインストール
RUN gemini extensions install https://github.com/github/github-mcp-server --consent

ENTRYPOINT ["/home/runner/entrypoint.sh"]
