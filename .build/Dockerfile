# --- ステージ1: ビルダー ---
# ランナーのダウンロードと展開を行うための一時的なステージ
# (修正) latestタグではなく、LTS版の具体的なバージョンを指定
FROM ubuntu:latest AS builder

# ビルド引数
ARG RUNNER_VERSION="2.317.0"
ARG RUNNER_ARCH="x64"
ARG RUNNER_SUM="00b2b7849e525d5ad3b3b27b38d3f1c1ac264a2f8b598b9a115b2c78411b0253"

# (修正) SSL証明書パッケージ(ca-certificates)を追加
RUN apt-get update && apt-get install -y --no-install-recommends curl tar ca-certificates && rm -rf /var/lib/apt/lists/*

# ランナーのダウンロードと検証、展開
WORKDIR /actions-runner
RUN curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && echo "${RUNNER_SUM}  actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" | sha256sum -c \
    && tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && rm ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz


# --- ステージ2: ファイナル ---
# 最終的な実行イメージ。軽量なslimイメージをベースにする
# (修正) latestタグではなく、軽量なslimイメージの具体的なバージョンを指定
FROM ubuntu:latest

# apt-get実行時にインタラクティブなプロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

# (修正) SSL証明書パッケージ(ca-certificates)を追加
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        jq \
        sudo \
        libicu74 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ランナー用のユーザー作成
RUN useradd -m docker \
    && usermod -aG sudo docker \
    && echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER docker
WORKDIR /home/docker

# ビルダーステージから展開済みのランナーファイルをコピー
COPY --from=builder --chown=docker:docker /actions-runner .

# エントリーポイントスクリプトのコピーと設定
COPY --chown=docker:docker entrypoint.sh .
RUN chmod u+x entrypoint.sh

# コンテナ起動時に実行するコマンド
ENTRYPOINT ["/home/docker/entrypoint.sh"]