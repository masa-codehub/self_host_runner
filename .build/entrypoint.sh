#!/bin/bash

# Fail fast and treat unset variables as errors
set -euo pipefail

# 環境変数が設定されていない場合はエラーで終了（カスタムメッセージ）
if [ -z "${REPO_URL:-}" ]; then
    echo "ERROR: REPO_URL is not set" >&2
    exit 1
fi
if [ -z "${RUNNER_TOKEN:-}" ]; then
    echo "ERROR: RUNNER_TOKEN is not set" >&2
    exit 1
fi

# ランナーの名前（指定がなければホスト名）
RUNNER_NAME=${RUNNER_NAME:-"runner-$(hostname)"}
# ランナーのラベル（オプション）
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,linux,x64"}
# ランナーのワーキングディレクトリ（オプション）
RUNNER_WORKDIR=${RUNNER_WORKDIR:-"_work"}

# クリーンアップ処理: スクリプト終了時にランナーを削除する（冪等）
cleanup() {
        echo "Removing runner..."
        if [ -x ./config.sh ]; then
                # ignore errors during remove to avoid masking original exit status
                ./config.sh remove --token "${RUNNER_TOKEN}" || true
        else
                echo "Warning: config.sh not found or not executable, skipping remove" >&2
        fi
}

# SIGINT(Ctrl+C) または SIGTERM を受け取ったときに cleanup 関数を呼び出す
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# GitHub Actions ランナーの設定
if [ ! -x ./config.sh ]; then
    echo "ERROR: config.sh not found or not executable in $(pwd)" >&2
    exit 2
fi

./config.sh --url "${REPO_URL}" \
                        --token "${RUNNER_TOKEN}" \
                        --name "${RUNNER_NAME}" \
                        --labels "${RUNNER_LABELS}" \
                        --work "${RUNNER_WORKDIR}" \
                        --unattended \
                        --replace

# ランナーを起動し、バックグラウンドジョブとして実行
# 'wait $!' を使うことで、シグナルを正しく受け取れるようにする
if [ ! -x ./run.sh ]; then
    echo "ERROR: run.sh not found or not executable" >&2
    cleanup
    exit 3
fi

./run.sh &
wait $!