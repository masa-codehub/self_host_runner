# --- ステージ1: Pythonのビルドステージ ---
FROM python:slim AS python-source

# --- ステージ2: Node.js公式イメージ---
FROM node:slim AS node-source

# --- ステージ3: ランナーのダウンロードステージ ---
FROM ubuntu:latest AS runner-builder

# apt-get実行時にインタラクティブなプロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ランナーのダウンロードと検証、展開
WORKDIR /actions-runner
# 1. GitHub APIを叩いて最新リリースのJSONを取得
# 2. jqで "tag_name" (例: "v2.317.0") を抽出
# 3. sedで先頭の "v" を削除してバージョン番号だけにする (例: "2.317.0")
# 4. 構築したURLでダウンロードする
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//') \
    && echo "Detected latest runner version: ${LATEST_VERSION}" \
    && RUNNER_ARCH="x64" \
    && curl -o actions-runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${LATEST_VERSION}.tar.gz" \
    && tar xzf ./actions-runner.tar.gz \
    && rm ./actions-runner.tar.gz

# --- ステージ4: 最終的な実行イメージ ---
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Pythonの実行に必要な "ランタイム" 依存関係と、CI/ランナーに必要なツールのみをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
        libssl-dev zlib1g libbz2-1.0 libreadline8 libsqlite3-0 libffi8 liblzma5 \
        git \
        curl \
        jq \
        sudo \
        gnupg \
        ca-certificates \
        lsb-release \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI の公式リポジトリを登録して最新の gh をインストール
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Google Cloud CLI (gcloud) のインストール
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# python-sourceステージから、ビルド済みのPythonをコピー
COPY --from=python-source /usr/local /usr/local

# node-sourceステージから、ビルド済みのnode.jsをコピー
COPY --from=node-source /usr/local /usr/local

# ライブラリの更新通知とパス設定
RUN ldconfig
ENV PATH="/usr/local/bin:${PATH}"

# Gemini CLIのインストール
RUN npm install -g @google/gemini-cli@preview

# ランナー用のユーザー作成
RUN useradd -m runner \
    && usermod -aG sudo runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# スクリプト類をコピー
WORKDIR /home/runner
# runner-builderステージからランナーのファイルをコピー
COPY --from=runner-builder --chown=runner:runner /actions-runner .
# エントリーポイントスクリプトをコピーして実行権限を付与
COPY --chown=runner:runner .build/entrypoint.sh .
RUN chmod u+x .build/entrypoint.sh

# 公式スクリプトを使って依存関係をインストール
# これにより、Ubuntuのバージョンに合わせて適切なライブラリ(libicuなど)が入る
RUN sudo ./bin/installdependencies.sh

USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]

# Memo : Gemini CLI Authentication
# docker exec -it <コンテナ名> bash
# gcloud auth application-default login --no-browser
