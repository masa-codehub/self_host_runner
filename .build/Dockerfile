# --- 最終的な実行イメージ (Ubuntuベースで一本化) ---
FROM ubuntu:latest

# ビルド時のみ対話型プロンプトを無効化
ARG DEBIAN_FRONTEND=noninteractive

# 1. uv のインストール (公式イメージからバイナリをコピー)
# これが最も確実で、システム全体(/usr/local/bin)で使えるようになります
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# 2. 基本ツールと依存関係のインストール
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
        gawk \
    && rm -rf /var/lib/apt/lists/*

# 3. Python のインストール
RUN add-apt-repository ppa:deadsnakes/ppa -y && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-dev \
        python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    # python3 コマンドを python としても使えるようにする
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 4. Node.js のインストール (NodeSource Current)
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# 5. GitHub CLI のインストール
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# 6. Google Cloud CLI (gcloud) のインストール
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# 7. Gemini CLI のインストール
RUN npm install -g @google/gemini-cli@preview

# 8. ランナー用のユーザー作成
RUN useradd -m runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 9. GitHub Actions Runner のダウンロードと展開
WORKDIR /home/runner
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//') \
    && curl -o actions-runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz" \
    && tar xzf ./actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner /home/runner

# 10. スクリプト類をコピーして権限設定
COPY --chown=runner:runner .build/entrypoint.sh .
# installdependencies.sh はOSのパッケージを入れるものなので、ビルド時に一度走らせればOKですが
# uv環境では依存関係解決能力が高いため、必須でない場合もあります。念のため残します。
RUN chmod u+x entrypoint.sh && sudo ./bin/installdependencies.sh

# 実行ユーザーに切り替え
USER runner

# 起動時に uv の設定などを行いたい場合は entrypoint.sh 側で制御します
ENTRYPOINT ["/home/runner/entrypoint.sh"]