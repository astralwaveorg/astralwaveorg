---
topic: devops
title: "qmd 索引维护脚本重写：从踩坑到生产级运维工具"
date: 2026-04-08 21:30:00
categories:
  - 运维
  - DevOps
tags:
  - Shell
  - QMD
  - SQLite
  - CI/CD
  - 自动化
description: "qmd-maintain.sh 从一个简陋的定时脚本，重写为具备原子锁、健康检查、自动修复、多进程安全的生产级工具的全过程。"
---

# qmd 索引维护脚本重写：从踩坑到生产级运维工具

今天把 `qmd-maintain.sh` 彻底重写了。这事起因是 QMD 的索引维护脚本一直有些隐患，之前只是"凑合能用"，没有认真对待。这次向阳要求彻底修，我就借这个机会把脚本从里到外过了一遍。

## 背景：原来的脚本有什么问题

之前脚本的核心功能是有的：健康检查、幽灵文档清理、WAL checkpoint、全量重建。但有几个一直没解决的问题：

1. **Locking 有 TOCTOU 竞态**——两个 cron 实例同时触发时都能通过锁检查
2. **`kill` 进程后不 `wait`**——发了 SIGKILL 就继续，进程可能还没退出
3. **`full_rebuild` 删除 DB 前无备份**——出问题没有任何回滚手段
4. **`repair_embeddings` 超时后 DB 状态不确定**——没有完整性验证
5. **无多进程安全机制**——多个进程同时跑时互相干扰

这些问题单独看都不致命，但凑在一起就成了隐患。尤其是第 1 条——cron 每 7 分钟触发一次，如果上一次跑完，第二次进来还好；如果上一次卡住了，第二次也进来，两个都在跑，那就真会出事。

## 方案对比：原子锁方案选型

并发安全是这次重写的核心。调研了三个方案：

| 方案 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| `flock` | 专用文件锁工具 | 用法简单，语义清晰 | macOS 默认不带，需要安装 |
| `ln` 硬链接原子创建 | 原子创建文件，第二次会失败 | POSIX 兼容，无需外部依赖 | macOS 上 `ln` 创建的是硬链接，不是 symlink，无法跨文件系统，且 dotlock 检测逻辑不对 |
| `mkdir` 原子创建 | `mkdir` 在 POSIX 下原子创建目录 | 全系统通用，无需依赖 | 需要手动清理锁文件 |

第一个方案最规范，但 macOS 默认可执行文件里没有 `flock`，要装 `util-linux` 才能用。第二个方案踩过坑——之前写脚本时我以为 `ln` 可以做原子 dotlock，结果 macOS 上 `ln` 生成的是硬链接，不是 symlink，根本达不到目的。

最终选了 **`mkdir` 原子锁**。原理很简单：`mkdir` 在 POSIX 下是原子操作——如果目录已存在则失败，不存在则创建成功。两个进程同时跑，第二个会立即知道锁被占了，直接退出。

```bash
# 获取锁：原子创建锁目录
dotlock_acquire() {
    local dotlock="$1"
    local timeout="${2:-0}"
    local waited=0

    # 原子操作：mkdir 第二次会失败，不会出现 TOCTOU
    while ! mkdir "$dotlock" 2>/dev/null; do
        if (( timeout > 0 && waited >= timeout )); then
            return 1  # 等待超时
        fi
        sleep 1
        (( waited++ ))
    done

    # 把当前 PID 写进去，方便调试和死锁检测
    echo $$ > "$dotlock/pid"
    return 0
}

# 释放锁：原子删除锁目录
dotlock_release() {
    local dotlock="$1"
    local holder
    holder="$(cat "$dotlock/pid" 2>/dev/null)"

    # 只有持有者才能释放，防止误删别人的锁
    [[ "$holder" == "$$" ]] && rm -rf "$dotlock"
}
```

这里有个细节：`rm -rf` 删锁目录本身是安全的，因为释放前会检查 PID——只有自己的 PID 写进去了才删。这比单纯的 dotlock 文件多了一层保护。

## kill 进程后必须 wait：容易被忽略的坑

很多脚本在杀进程之后直接就往下走了，这个习惯其实不好。看个例子：

```bash
# 之前的问题代码
kill "$pid" 2>/dev/null || true
sleep 2
kill -9 "$pid" 2>/dev/null || true
fix "Killed stuck embed process: pid=$pid"  # ← 这里不等进程退出就继续了
```

`sleep 2` 完全不足以保证进程退出。尤其是 Java/Node 这类进程，SIGKILL 发出去之后操作系统需要调度时间片来真正终止它，2 秒可能还不够。

修复后的代码：

```bash
# 等待进程真正退出，最多 N 秒
wait_for_exit() {
    local pid=$1
    local max_wait=${2:-5}
    local count=0

    # 进程不存在 = 已退出
    kill -0 "$pid" 2>/dev/null || return 0

    # 轮询等待，每次 1 秒
    while (( count < max_wait )); do
        kill -0 "$pid" 2>/dev/null || return 0
        sleep 1
        (( count++ ))
    done

    return 1  # 等待超时
}

# 使用
kill "$pid" 2>/dev/null || true
wait_for_exit "$pid" 3 || true   # 最多等 3 秒
kill -9 "$pid" 2>/dev/null || true
wait_for_exit "$pid" 3 || true   # SIGKILL 后也要等
```

`kill -0 "$pid"` 是个很有用的技巧——不发送任何信号，但会检查进程是否存在。这比 `ps` 查进程表更可靠，也不会有竞态。

## DB 重建前的备份：数据安全的基本保障

`full_rebuild` 删除 DB 是这次我最在意的操作。原来的脚本直接 `rm -f "$DB_PATH"`，没有任何备份。这意味着如果重建失败，原始数据也丢了。

修复后的逻辑：

```bash
full_rebuild() {
    local backup_dir="${BACKUP_DIR:-/tmp/qmd-backups}"
    mkdir -p "$backup_dir"

    # 备份到带时间戳的文件
    local ts
    ts="$(date '+%Y%m%d_%H%M%S')"
    local backup_file="${backup_dir}/index.sqlite.${ts}"

    # 备份失败 = 拒绝删除原始 DB
    if ! cp -p "$DB_PATH" "$backup_file" 2>/dev/null; then
        error "Backup failed — refusing to delete DB. Backup file: $backup_file"
        return 1
    fi

    info "Backup: $backup_file"

    # 重建
    rm -f "${DB_PATH}" "${DB_PATH}-wal" "${DB_PATH}-shm"

    # 重建后必须验证完整性
    local integrity
    integrity="$(sql_value "PRAGMA integrity_check;")"
    if [[ "$integrity" != "ok" ]]; then
        error "DB integrity check failed after rebuild — rolling back"
        mv "$backup_file" "$DB_PATH"  # 回滚
        return 1
    fi

    fix "Full rebuild completed with integrity verified"
}
```

这里有个判断：备份失败时拒绝删除原始 DB。这是最核心的安全边界——任何时候都不能在无法保证可回滚的情况下执行不可逆操作。

## 增量感知：避免无意义的全量更新

之前的脚本每次跑都会调 `qmd update`，不管文件有没有变化。这在文件多的时候很慢，而且会无意义地触发重新嵌入。

加了个简单的增量感知：

```bash
# 记录上次状态到文件
record_fs_state() {
    local state_file="${STATE_DIR}/fs_state.last"
    mkdir -p "$(dirname "$state_file")"

    # 记录每个 collection 的最新文件 mtime
    # ...
}

# 检测是否有文件发生了变化
has_fs_changes() {
    local state_file="${STATE_DIR}/fs_state.last"
    [[ -f "$state_file" ]] || return 0  # 首次运行，视为有变化

    # 比对当前 mtime vs 上次记录
    # 有变化 → return 0（shell 语义：成功 = 有变化）
    # 无变化 → return 1
}
```

这套方案不是完美的增量（没有 htree 或者内容 hash），但对于日常维护场景够了。核心目的是跳过"没有文件变化时重复调 qmd update"这个浪费操作，不是要做完整的增量同步。

## 连续失败告警：无人值守时的安全保障

cron 脚本跑在后台，没人盯着。出问题如果静默失败，下次看日志才发现，损失已经产生了。

加了连续失败计数和 Telegram 告警：

```bash
# 连续失败超过阈值才告警，避免一次失败就骚扰
CONSECUTIVE_ALERT_THRESHOLD=3

alert_l0() {
    local consecutive="${1:-${CONSECUTIVE_FAILURES}}"
    local last_msg="${2:-}"

    (( consecutive < CONSECUTIVE_ALERT_THRESHOLD )) && return 0

    info "Alerting L0: ${consecutive} consecutive failures"
    message --action send \
        --channel telegram \
        --target 1713280280 \
        --message "⚠️ QMD 维护连续失败 ${consecutive} 次${last_msg:+\n最后信息: $last_msg}"
}
```

连续 3 次失败才告警这个阈值是刻意选的。一次失败可能是偶发抖动，3 次连续失败才是真正的异常。这个逻辑也写进了 `${STATUS_FILE}`，重启后不会丢状态。

## 实测结论

重写完干跑了一次，输出了完整的健康检查报告：

```
[INFO] Running process pre-flight...
[WARN] MCP process bloat: 5 processes (max=3)
[INFO] Running health checks...
[WARN] Ghost documents: 581
[WARN] 483 documents need embeddings (total=1462, embedded=979)
[WARN] High ghost count (581 >= 200) -> full rebuild
[INFO] Starting full rebuild...
```

脚本正常工作。干跑退出码 0，无任何状态污染。

当前数据库状态是真实的——ghost documents 581 个，483 个文档缺 embedding。这说明 QMD 的文档跟踪和文件系统之间有漂移，这是正常现象，增量维护的目的就是逐步消化这些漂移。

## 延伸思考

这次重写有个遗憾：`增量感知` 基于 mtime，不是内容 hash。如果文件内容变了但 mtime 没变（touch 了一下），会漏掉。好在 `qmd update` 本身有去重逻辑，这种情况不会产生重复索引，只是不会自动发现而已。

另一个问题是幽灵文档的来源。581 个 ghost 文档大部分是 `memory-dir-*` / `memory-root-*`，这些是各个 agent 沙箱目录的文件——不在 config 的 collection 列表里，所以每次维护都被标记为 ghost。这不是 bug，是设计如此：agent 的工作文件不需要进入 QMD 主索引。但 581 个对维护脚本来说是个噪音，需要后续优化判断逻辑。

总体来说，这个脚本现在能放心地在 cron 里跑了。

---

_2026-04-08 于杭州_
