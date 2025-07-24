---
title: qBittorrent 馒头自动化版刷流
layout: post
published: true
categories:
  - python
tags:
  - python
description: 自动化版刷流+自动删种脚本
author: Astral
lang: zh-CN
date: 2025-04-30 01:46:26
---


## 自动化版刷流+自动删种脚本**

满足以下所有功能：

1. **刷流自动化**（筛种/加种/记录）
2. **自动删种**（支持做种时间&上传比例阈值）
3. **删种日志&推送集成**（TG/Server酱通知，包括谁因啥被删、记录日志文件）
4. **数据定期备份**（每次执行备份`flood_data.json`到`flood_data_bak_YYYYMMDDHHMMSS.json`）
5. **依然单文件，直接复制即用**
6. **充分注释，便于进一步自定义**


## 🌟 使用说明

- 请先配置好脚本头部参数（可通过环境变量覆盖）。
- 必须设置 `APIKEY`、`QBURL`、`QBUSER`、`QBPWD`、`BOT_TOKEN`/`CHAT_ID`等为你的值。
- 脚本每次执行都会**备份flood_data.json到当前目录以防意外丢失**。
- 所有自动删除都会记录到 `delete_log.txt` 并推送到TG/Server酱。
- 推荐用 `crontab` 等循环定时执行。
- 删除策略：
    - 做种时间≥AUTO_REMOVE_TIME（默认8小时）
    - 上传≥AUTO_REMOVE_RATIO倍（默认2x）
    - 满足任一即删！


---

**复制下方全部内容即可用！**


```python
import os
import json
import logging
import requests
import re
import time
import random
from datetime import datetime, timedelta
import pytz
import xml.etree.ElementTree as ET
from dateutil import parser
import shutil

# ========== 参数和常量 ==========
def str2bool(val):
    return str(val).lower() in (“1”, “true”, “yes”, “on”)

def get_env_int(var, default, multiplier=1):
    try:
        return int(float(os.environ.get(var, default))) * multiplier
    except Exception:
        return int(default) * multiplier

# 核心配置区（环境变量优先，配置项次之）
QBURL = os.environ.get(“QBURL”, “http://127.0.0.1:8080”)
QBUSER = os.environ.get(“QBUSER”, “astral”)
QBPWD = os.environ.get(“QBPWD”, “passwd”)
APIKEY = os.environ.get(“APIKEY”, “请填写”)
DOWNLOADPATH = os.environ.get(“DOWNLOADPATH”, “/data/qb/MTBrush”)
SEND_URL = os.environ.get(“SEND_URL”, None)
RSS = os.environ.get(“RSS”, “https://rss.m-team.cc/api/rss/fetch”)
SPACE = get_env_int(“SPACE”, 40, 1024 ** 3)
MAX_SIZE = get_env_int(“MAX_SIZE”, 30, 1024 ** 3)
MIN_SIZE = get_env_int(“MIN_SIZE”, 1, 1024 ** 3)
FREE_TIME = get_env_int(“FREE_TIME”, 10, 60 * 60)
PUBLISH_BEFORE = get_env_int(“PUBLISH_BEFORE”, 24, 60 * 60)
BOT_TOKEN = os.environ.get(“BOT_TOKEN”, “”)
CHAT_ID = int(os.environ.get(“CHAT_ID”, “0”))
TAGS = os.environ.get(“TAGS”, “MT刷流,MTBrush”)
LS_RATIO = float(os.environ.get(“LS_RATIO”, 1))
IPV6 = str2bool(os.environ.get(“IPV6”, False))
GET_METHOD = str2bool(os.environ.get(“GET_METHOD”, False))
PROXY = os.environ.get(“PROXY”, None)
DATA_FILE = “flood_data.json”
DELETE_LOG_FILE = “delete_log.txt”

# 自动删种设置
AUTO_REMOVE_TIME = get_env_int(“AUTO_REMOVE_TIME”, 8, 3600)  # 8小时（秒）
AUTO_REMOVE_RATIO = float(os.environ.get(“AUTO_REMOVE_RATIO”, 2))  # 2倍上传量删除
BACKUP_KEEP = get_env_int(“BACKUP_KEEP”, 7, 1)  # 保留最近N份数据备份

tzinfos = {“CST”: pytz.timezone(“Asia/Shanghai”)}
NAMESPACE = {“dc”: “http://purl.org/dc/elements/1.1/“}
UNIT_LIST = [“B”, “KB”, “MB”, “GB”, “TB”, “PB”]

# ========== 日志配置 ==========
logging.basicConfig(
    level=logging.INFO,
    format=“%(asctime)s | %(levelname)s | %(message)s”
)

# ========== Session初始化 ==========
DEFAULT_HEADERS = {
    “User-Agent”: “Mozilla/5.0 (compatible; MTeamScript/1.0; +https://github.com/xx)”
}
qb_session = requests.Session()
mt_session = requests.Session()
qb_session.headers.update(DEFAULT_HEADERS)
mt_session.headers.update(DEFAULT_HEADERS)
if PROXY:
    qb_session.proxies = mt_session.proxies = {“http”: PROXY, “https”: PROXY}

flood_torrents = []

# ========== 工具函数 ==========
def sleep_random(a=5, b=10):
    sec = random.randint(a, b)
    logging.info(f”⏳ 等待 {sec} 秒 ...”)
    time.sleep(sec)

def size_to_gb(val):
    return val / 1024 / 1024 / 1024

def format_gb(val):
    return “{:.2f}G”.format(size_to_gb(val))

def now_shanghai():
    return datetime.now(pytz.timezone(“Asia/Shanghai”))

# ========== 配置文件读写 ==========
def read_config():
    global flood_torrents
    if not os.path.exists(DATA_FILE):
        flood_torrents = []
        logging.info(f”💾 首次运行，未检测到历史记录！”)
        return
    try:
        with open(DATA_FILE, “r”, encoding=“utf-8”) as f:
            flood_torrents = json.load(f)
        if not isinstance(flood_torrents, list):
            flood_torrents = []
        logging.info(f”💾 成功载入历史记录 {len(flood_torrents)} 个”)
    except Exception as e:
        logging.warning(f”⚠️ 读取{DATA_FILE}失败: {e}”)
        flood_torrents = []

def save_config():
    try:
        with open(DATA_FILE, “w”, encoding=“utf-8”) as f:
            json.dump(flood_torrents, f, ensure_ascii=False, indent=4)
        logging.info(f”💾 历史记录写入成功（共 {len(flood_torrents)} 个）”)
    except Exception as e:
        logging.warning(f”⚠️ 写入{DATA_FILE}失败: {e}”)

# ========== 数据备份函数 ==========
def backup_data():
    if not os.path.exists(DATA_FILE):
        return
    bak_name = f”flood_data_bak_{datetime.now().strftime(‘%Y%m%d%H%M%S’)}.json”
    shutil.copyfile(DATA_FILE, bak_name)
    logging.info(f”🗃 历史数据已备份至 {bak_name}”)
    # 保留最近N份
    bak_files = [f for f in os.listdir(“.”) if f.startswith(“flood_data_bak_”) and f.endswith(“.json”)]
    bak_files = sorted(bak_files, reverse=True)
    for i in bak_files[BACKUP_KEEP:]:
        try:
            os.remove(i)
        except: pass

# ========== 推送/日志 ==========
def send_telegram_message(message):
    if not BOT_TOKEN or CHAT_ID == 0:
        return
    url = f”https://api.telegram.org/bot{BOT_TOKEN}/sendMessage”
    params = {“chat_id”: CHAT_ID, “text”: message}
    try:
        response = requests.get(url, params=params)
        if response.status_code == 200:
            logging.info(“📣 TG 已通知”)
        else:
            logging.warning(“⚠️ TG通知失败”)
    except requests.exceptions.RequestException as e:
        logging.error(f”❌ TG通知异常：{e}”)

def send_server3_message(message):
    if not SEND_URL:
        return
    url = f”{SEND_URL}”
    data = {“title”: “M-Team 刷流”, “desp”: message}
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            logging.info(“📣 Server酱 已通知”)
        else:
            logging.warning(“⚠️ Server酱通知失败”)
    except requests.exceptions.RequestException as e:
        logging.error(f”❌ Server酱异常：{e}”)

def log_delete(msg):
    “””追加日志到日志文件”””
    try:
        with open(DELETE_LOG_FILE, “a”, encoding=“utf-8”) as f:
            f.write(f”{datetime.now().strftime(‘%F %T’)} | {msg}\n”)
    except Exception:
        pass

def notice_and_log(msg):
    “””日志+推送多一层方便调用”””
    logging.info(msg)
    send_telegram_message(msg)
    send_server3_message(msg)
    log_delete(msg)

# ========== 业务逻辑 ==========
def get_torrent_detail(torrent_id):
    url = “https://api.m-team.cc/api/torrent/detail”
    try:
        response = mt_session.post(url, data={“id”: torrent_id})
        response.raise_for_status()
        data = response.json()[“data”]
        name = data[“name”]
        size = int(data[“size”])
        discount = data[“status”].get(“discount”, None)
        discount_end_time = data[“status”].get(“discountEndTime”, None)
        seeders = int(data[“status”][“seeders”])
        leechers = int(data[“status”][“leechers”])
        if discount_end_time is not None:
            discount_end_time = datetime.strptime(discount_end_time, “%Y-%m-%d %H:%M:%S”)
    except Exception as e:
        logging.warning(f”⚠️ 请求详情失败（ID: {torrent_id}）：{e}”)
        return None
    return {
        “name”: name,
        “size”: size,
        “discount”: discount,
        “discount_end_time”: discount_end_time,
        “seeders”: seeders,
        “leechers”: leechers,
    }

def add_torrent(url, name):
    add_torrent_url = QBURL + “/api/v2/torrents/add”
    if GET_METHOD:
        logging.info(f”📡 以本地文件上传方式添加：『{name}』”)
        try:
            response = mt_session.get(url)
            response.raise_for_status()
            files = {
                “torrents”: (f”{name}.torrent”, response.content, “application/x-bittorrent”)
            }
            data = {“tags”: TAGS, “savepath”: DOWNLOADPATH}
            resp_qb = qb_session.post(add_torrent_url, files=files, data=data)
        except Exception as e:
            logging.error(f”❌ 添加种子异常: {e}”)
            return False
    else:
        logging.info(f”📡 以URL推送方式添加：『{name}』”)
        try:
            resp_qb = qb_session.post(
                add_torrent_url,
                data={“urls”: url, “tags”: TAGS, “savepath”: DOWNLOADPATH},
            )
        except Exception as e:
            logging.error(f”❌ 添加种子异常: {e}”)
            return False

    if resp_qb.status_code != 200:
        logging.error(f”❌ 添加失败: {name}, 状态码: {resp_qb.status_code}”)
        return False

    msg = f”✅ 种子已添加：『{name}』”
    logging.info(msg)
    send_telegram_message(msg)
    send_server3_message(msg)
    return True

def get_disk_space():
    url = QBURL + “/api/v2/sync/maindata”
    try:
        response = qb_session.get(url)
        response.raise_for_status()
        data = response.json()
        disk_space = int(data[“server_state”][“free_space_on_disk”])
        logging.info(f”💾 剩余磁盘空间: {format_gb(disk_space)}”)
        return disk_space
    except Exception as e:
        logging.error(f”❌ 获取磁盘空间失败: {e}”)
        return None

def get_torrent_url(torrent_id):
    url = “https://api.m-team.cc/api/torrent/genDlToken”
    try:
        response = mt_session.post(url, data={“id”: torrent_id})
        response.raise_for_status()
        data = response.json()[“data”]
        params = f”?useHttps=true&type={‘ipv6’ if IPV6 else ‘ipv4’}&” + data.split(“?”)[1]
        download_url = f”{data.split(‘?’)[0]}{params}”
        return download_url
    except Exception as e:
        logging.warning(f”⚠️ 获取种子链接失败（ID:{torrent_id}）：{e}”)
        return None

def flood_task():
    global flood_torrents
    logging.info(“⚡️ 刷流任务启动”)
    disk_space = get_disk_space()
    if disk_space is None or disk_space <= SPACE:
        msg = f”💾 空间不足，停止刷流！剩余: {format_gb(disk_space) if disk_space else ‘未知’}”
        logging.warning(msg)
        send_telegram_message(msg)
        send_server3_message(msg)
        return

    try:
        response = mt_session.get(RSS)
        response.raise_for_status()
        logging.info(“📡 成功获取RSS”)
    except Exception as e:
        logging.error(f”❌ RSS请求失败: {e}”)
        return

    try:
        root = ET.fromstring(response.text)
    except ET.ParseError as e:
        logging.error(f”❌ RSS XML解析失败: {e}”)
        return

    for item in root.findall(“channel/item”, NAMESPACE):
        try:
            link = item.find(“link”).text
            torrent_id = re.search(r”\d+$”, link).group()
            publish_time = item.find(“pubDate”).text
            publish_time = parser.parse(publish_time, tzinfos=tzinfos)
            title = item.find(“title”).text
            matches = re.findall(r”\[(\d+(\.\d+)?)\s(B|KB|MB|GB|TB|PB)\]”, title.replace(“,”, “”))
            if not matches:
                logging.info(f”⏩ 跳过（无法分析大小）ID:{torrent_id} | 标题:{title}”)
                continue
            size, _, unit = matches[-1]
            size = int(float(size) * 1024 ** UNIT_LIST.index(unit))
            if any(torrent_id == torrent[“id”] for torrent in flood_torrents):
                logging.info(f”⏩ 跳过（已添加）ID:{torrent_id}”)
                continue
            if now_shanghai() - publish_time > timedelta(seconds=PUBLISH_BEFORE):
                logging.info(f”⏩ 跳过（过期）ID:{torrent_id}”)
                continue
            if size > MAX_SIZE:
                logging.info(f”⏩ 跳过（超出最大：{format_gb(MAX_SIZE)}）ID:{torrent_id}”)
                continue
            if size < MIN_SIZE:
                logging.info(f”⏩ 跳过（低于最小：{format_gb(MIN_SIZE)}）ID:{torrent_id}”)
                continue
            if disk_space - size < SPACE:
                logging.info(f”⏩ 跳过（下载后空间不足）ID:{torrent_id}”)
                continue
            logging.info(f”🔍 查询详情 ID:{torrent_id}”)
            sleep_random()
            detail = get_torrent_detail(torrent_id)
            if detail is None:
                continue
            name = detail[“name”]
            discount = detail[“discount”]
            discount_end_time = detail[“discount_end_time”]
            seeders = detail[“seeders”]
            leechers = detail[“leechers”]

            if discount is None or discount not in [“FREE”, “_2X_FREE”]:
                logging.info(f”⏩ 跳过（不是免费）ID:{torrent_id} | 状态:{discount}”)
                continue
            if discount_end_time and discount_end_time < datetime.now() + timedelta(seconds=FREE_TIME):
                logging.info(f”⏩ 跳过（免费剩余不足）ID:{torrent_id}”)
                continue
            if seeders <= 0:
                logging.info(f”⏩ 跳过（无人做种）ID:{torrent_id}”)
                continue
            if seeders and leechers and (seeders > 0) and (leechers / seeders <= LS_RATIO):
                logging.info(f”⏩ 跳过（下种比<{LS_RATIO}）ID:{torrent_id}”)
                continue
            logging.info(f”📦 添加种子『{name}』| 大小:{format_gb(size)} | ID:{torrent_id}”)
            sleep_random()
            download_url = get_torrent_url(torrent_id)
            if download_url is None:
                continue
            if not add_torrent(download_url, name):
                continue
            disk_space -= size
            flood_torrents.append(
                {
                    “name”: name,
                    “id”: torrent_id,
                    “time”: now_shanghai().strftime(“%Y-%m-%d %H:%M:%S”),
                    “size”: size,
                    “url”: download_url,
                    “discount”: discount,
                    “discount_end_time”: (
                        discount_end_time.strftime(“%Y-%m-%d %H:%M:%S”)
                        if discount_end_time is not None
                        else None
                    ),
                }
            )
            if disk_space <= SPACE:
                msg = f”💾 空间不足，中止刷流！（剩余: {format_gb(disk_space)})”
                logging.warning(msg)
                send_telegram_message(msg)
                send_server3_message(msg)
                break
        except Exception as e:
            logging.warning(f”⚠️ 处理种子异常: {e}”)

def auto_remove_seeded_torrents():
    global flood_torrents
    if not flood_torrents:
        return
    logging.info(“🧹 执行自动删种检测 ...”)
    url = QBURL + “/api/v2/torrents/info”
    try:
        resp = qb_session.get(url, params={“filter”: “all”})
        resp.raise_for_status()
        all_torrents = resp.json()
        will_remove = []
        for record in flood_torrents:
            found = None
            for t in all_torrents:
                if str(record.get(“name”, “”)).strip() == t.get(“name”, “”).strip():
                    found = t
                    break
            if not found:
                continue
            seeding_time = found.get(“seeding_time”, 0)  # 单位: 秒
            up = int(found.get(“uploaded”, 0))
            size = int(found.get(“size”, 1))
            ratio = up / size if size else 0
            # 满足任一条件均删
            cond1 = (AUTO_REMOVE_TIME > 0 and seeding_time >= AUTO_REMOVE_TIME)
            cond2 = (AUTO_REMOVE_RATIO > 0 and ratio >= AUTO_REMOVE_RATIO)
            if cond1 or cond2:
                will_remove.append((found, record, seeding_time, ratio))
        for t, record, sew, ratio in will_remove:
            try:
                msg = f”🧹 删除种子:『{t[‘name’]}』” \
                      f”\n→ 做种:{sew//3600}h{sew%3600//60}m 上传:{format_gb(t.get(‘uploaded’,0))}({ratio:.2f}x)”
                del_url = QBURL + “/api/v2/torrents/delete”
                params = {
                    “hashes”: t[“hash”],
                    “deleteFiles”: “true”
                }
                resp_del = qb_session.post(del_url, data=params)
                if resp_del.status_code == 200:
                    notice_and_log(msg)
                else:
                    err_msg = f”⚠️ 种子删除失败: {t[‘name’]} 状态码:{resp_del.status_code}”
                    notice_and_log(err_msg)
                flood_torrents.remove(record)
            except Exception as ex:
                logging.warning(f”⚠️ 自动删种操作异常：{t.get(‘name’,’?’)} - {ex}”)
    except Exception as e:
        logging.warning(f”⚠️ 获取种子状态失败: {e}”)

def login():
    login_url = QBURL + “/api/v2/auth/login”
    login_data = {“username”: QBUSER, “password”: QBPWD}
    try:
        resp = qb_session.post(login_url, data=login_data)
        if resp.status_code != 200:
            logging.error(f”❌ QB登录失败，状态码: {resp.status_code}”)
            return False
        mt_session.headers.update({“x-api-key”: APIKEY})
        logging.info(“✅ QB登录成功”)
        return True
    except Exception as e:
        logging.error(f”❌ QB登录异常：{e}”)
        return False

if __name__ == “__main__”:
    logging.info(“🚀 脚本启动”)
    backup_data()        # 启动先备份
    read_config()
    if not login():
        logging.error(“❌ 程序退出（QB登录失败）”)
        exit(1)
    flood_task()
    auto_remove_seeded_torrents()
    save_config()
    logging.info(“🏁 脚本运行结束”)
  

```