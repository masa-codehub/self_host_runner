# --- ステージ1: ランナーのダウンロードステージ ---
FROM ubuntu:latest AS runner-builder

# ビルド引数
ARG RUNNER_VERSION="2.317.0"
ARG RUNNER_ARCH="x64"
ARG RUNNER_SUM="00b2b7849e525d5ad3b3b27b38d3f1c1ac264a2f8b598b9a115b2c78411b0253"

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ランナーのダウンロードと検証、展開
WORKDIR /actions-runner
RUN curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && echo "${RUNNER_SUM}  actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" | sha256sum -c \
    && tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz


# --- ステージ2: 最終的な実行イメージ ---
# PythonとCIに必要なシステムライブラリのみをインストールしたイメージ
FROM python:3.13-slim

ENV DEBIAN_FRONTEND=noninteractive

# CIで必要とされていたシステムライブラリと、ランナーの動作に必要なツールをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        jq \
        sudo \
        libicu74 \
        ca-certificates \
        libsqlite3-dev \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*

# ランナー用のユーザー作成
RUN useradd -m docker \
    && usermod -aG sudo docker \
    && echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER docker
WORKDIR /home/docker

# ステージ1からランナーのファイルをコピー
COPY --from=runner-builder --chown=docker:docker /actions-runner .

# エントリーポイントスクリプトをコピーして実行権限を付与
COPY --chown=docker:docker .build/entrypoint.sh .
RUN chmod u+x entrypoint.sh

# コンテナ起動時のコマンド
ENTRYPOINT ["/home/docker/entrypoint.sh"]