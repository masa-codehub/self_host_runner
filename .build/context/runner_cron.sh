#!/bin/bash
# ================================================================
# self host runner 自動アップデートスクリプト
#
# crontab -e で編集
# 分 時 日 月 曜日 (0=日曜)
# 0 3 * * 0 /opt/runner/runner_cron.sh
# ================================================================
set -eu

# ------------------------------------
# 設定：最大待機時間（分）
# ジョブ実行中の場合、ここで設定した時間までは待ち続けます
# ------------------------------------
MAX_WAIT_MINUTES=60

# 多重起動防止
LOCKFILE="/tmp/runner_cron.lock"
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "[Skip] Script is already running."
    exit 0
fi
echo $$ > ${LOCKFILE}
trap 'rm -f ${LOCKFILE}' EXIT

WORK_DIR="./self_host_runner"
cd $WORK_DIR

echo "=== Weekly Maintenance Start: $(date) ==="

# 1. 常に最新コードを取得
echo " -> Fetching latest code..."
git fetch origin
git reset --hard origin/main

# 2. 常に最新イメージをビルド
echo " -> Pulling & Building latest images..."
docker compose build --pull --no-cache 

# 3. サービス毎の更新
SERVICES=$(docker compose config --services)

for SERVICE in $SERVICES; do
    echo "------------------------------------------------"
    echo "Processing Service: $SERVICE"

    CONTAINER_ID=$(docker compose ps -q $SERVICE || true)
    
    # コンテナが起動していない場合は、即座に作成へ進む
    if [ -n "$CONTAINER_ID" ]; then
        
        # 待機ループ開始
        WAIT_COUNT=0
        while docker top $SERVICE | grep -q "Runner.Worker"; do
            # タイムアウト判定
            if [ $WAIT_COUNT -ge $MAX_WAIT_MINUTES ]; then
                echo "  -> [TIMEOUT] Waited $MAX_WAIT_MINUTES mins but runner is still busy."
                echo "  -> Skipping update for $SERVICE to ensure safety."
                # 次のサービスへ（このサービスは更新しない）
                continue 2
            fi

            echo "  -> [BUSY] Runner is busy. Waiting 1 minute... ($((WAIT_COUNT + 1))/${MAX_WAIT_MINUTES} mins)"
            sleep 60
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done
        
        if [ $WAIT_COUNT -gt 0 ]; then
            echo "  -> [IDLE] Runner is now free."
        fi
    fi

    echo "  -> Updating/Restarting $SERVICE..."
    docker compose up -d --no-deps $SERVICE
done

echo "Cleanup..."
docker image prune -f
echo "Done: $(date)"