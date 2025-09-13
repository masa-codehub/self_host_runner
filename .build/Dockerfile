# --- ステージ1: Pythonのビルドステージ ---
FROM ubuntu:latest AS python-builder

# apt-get実行時にインタラクティブなプロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

# Pythonのバージョンを環境変数として定義
ENV PYTHON_VERSION=3.13.3

# Pythonのビルドに必要な依存関係をインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && update-ca-certificates \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        curl \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Pythonをソースからビルドし、/usr/local/python ディレクトリにインストール
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar -xf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations --prefix=/usr/local/python \
    && make -j $(nproc) \
    && make install \
    && /usr/local/python/bin/python3.13 -m ensurepip \
    && /usr/local/python/bin/python3.13 -m pip install --upgrade pip \
    && cd .. \
    && rm -rf Python-${PYTHON_VERSION}*

# --- ステージ2: ランナーのダウンロードステージ ---
FROM ubuntu:latest AS runner-builder

# apt-get実行時にインタラクティブなプロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

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


# --- ステージ3: 最終的な実行イメージ ---
FROM ubuntu:latest

# apt-get実行時にインタラクティブなプロンプトを無効化
ENV DEBIAN_FRONTEND=noninteractive

# Pythonの実行に必要な "ランタイム" 依存関係と、CI/ランナーに必要なツールのみをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
        # # Pythonの実行時依存
        # libssl-dev zlib1g libbz2-1.0 libreadline8 libsqlite3-0 libffi8 liblzma5 \
        # CIとランナー用
        git \
        jq \
        sudo \
        libicu74 \
        ca-certificates \
        libsqlite3-dev \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*

# python-builderステージから、ビルド済みのPythonをコピー
COPY --from=python-builder /usr/local/python /usr/local/python

# python と pip コマンドにパスを通す
ENV PATH="/usr/local/python/bin:${PATH}"

# ランナー用のユーザー作成
RUN useradd -m docker \
    && usermod -aG sudo docker \
    && echo "docker ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER docker
WORKDIR /home/docker

# runner-builderステージからランナーのファイルをコピー
COPY --from=runner-builder --chown=docker:docker /actions-runner .

# エントリーポイントスクリプトをコピーして実行権限を付与
COPY --chown=docker:docker entrypoint.sh .
RUN chmod u+x entrypoint.sh

# コンテナ起動時のコマンド
ENTRYPOINT ["/home/docker/entrypoint.sh"]