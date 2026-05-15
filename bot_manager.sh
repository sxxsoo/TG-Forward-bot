#!/bin/bash

CONFIG_FILE="/root/telegram-bot/bot_config.py"
INSTALL_DIR="/root/telegram-bot"
SERVICE_FILE="/etc/systemd/system/telegram-bot.service"
SCRIPT_FILE="/root/bot_manager.sh"
THREAD_CONFIG_FILE="/root/telegram-bot/thread_config.py"

if [ ! -x "$SCRIPT_FILE" ]; then
    chmod +x "$SCRIPT_FILE"
    echo "已自动设置执行权限"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

format_python_list() {
    local input_str="$1"
    if [ -z "$input_str" ]; then
        echo "[]"
        return
    fi
    
    IFS=',' read -ra item_array <<< "$input_str"
    local python_str="["
    for i in "${!item_array[@]}"; do
        if [ $i -ne 0 ]; then
            python_str+=", "
        fi
        local item="${item_array[$i]}"
        item=$(echo "$item" | xargs)
        python_str+="'$item'"
    done
    python_str+="]"
    echo "$python_str"
}

save_config_to_file() {
    mkdir -p "$(dirname "$CONFIG_FILE")"

    local channels_py=$(format_python_list "$REQUIRED_CHANNELS")
    local keywords_py=$(format_python_list "$FILTER_KEYWORDS")
    local targets_py=$(format_python_list "$GROUP_CHAT_ID")

    cat > "$CONFIG_FILE" << EOL
BOT_TOKEN = "$BOT_TOKEN"
ADMIN_USER_ID = $ADMIN_USER_ID
GROUP_CHAT_ID = $targets_py
REQUIRED_CHANNELS = $channels_py
FILTER_KEYWORDS = $keywords_py
SHOW_USERNAME = $SHOW_USERNAME
SHOW_USER_ID = $SHOW_USER_ID
SHOW_TIMESTAMP = $SHOW_TIMESTAMP
DATABASE_NAME = "bot_database.db"
EOL
    echo "✅ 配置已保存并更新！"
}

read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        BOT_TOKEN=$(grep "BOT_TOKEN" "$CONFIG_FILE" | awk -F'"' '{print $2}')
        ADMIN_USER_ID=$(grep "ADMIN_USER_ID" "$CONFIG_FILE" | awk '{print $3}')
        
        if grep -q "GROUP_CHAT_ID" "$CONFIG_FILE"; then
            if grep -q "GROUP_CHAT_ID = \[" "$CONFIG_FILE"; then
                GROUP_CHAT_ID=$(grep "GROUP_CHAT_ID" "$CONFIG_FILE" | sed 's/.*= \[\([^]]*\)\].*/\1/' | sed "s/'//g; s/ //g")
            else
                GROUP_CHAT_ID=$(grep "GROUP_CHAT_ID" "$CONFIG_FILE" | awk '{print $3}')
            fi
        else
            GROUP_CHAT_ID=""
        fi
        
        if grep -q "REQUIRED_CHANNELS" "$CONFIG_FILE"; then
            REQUIRED_CHANNELS=$(grep "REQUIRED_CHANNELS" "$CONFIG_FILE" | sed 's/.*= \[\([^]]*\)\].*/\1/' | sed "s/'//g; s/ //g")
        else
            REQUIRED_CHANNELS=""
        fi
        
        if grep -q "FILTER_KEYWORDS" "$CONFIG_FILE"; then
            FILTER_KEYWORDS=$(grep "FILTER_KEYWORDS" "$CONFIG_FILE" | sed 's/.*= \[\([^]]*\)\].*/\1/' | sed "s/'//g; s/ //g")
        else
            FILTER_KEYWORDS=""
        fi
        
        if grep -q "SHOW_USERNAME" "$CONFIG_FILE"; then
            SHOW_USERNAME=$(grep "SHOW_USERNAME" "$CONFIG_FILE" | awk '{print $3}')
        else
            SHOW_USERNAME="True"
        fi
        
        if grep -q "SHOW_USER_ID" "$CONFIG_FILE"; then
            SHOW_USER_ID=$(grep "SHOW_USER_ID" "$CONFIG_FILE" | awk '{print $3}')
        else
            SHOW_USER_ID="True"
        fi
        
        if grep -q "SHOW_TIMESTAMP" "$CONFIG_FILE"; then
            SHOW_TIMESTAMP=$(grep "SHOW_TIMESTAMP" "$CONFIG_FILE" | awk '{print $3}')
        else
            SHOW_TIMESTAMP="True"
        fi
    else
        BOT_TOKEN=""
        ADMIN_USER_ID=""
        GROUP_CHAT_ID=""
        REQUIRED_CHANNELS=""
        FILTER_KEYWORDS=""
        SHOW_USERNAME="True"
        SHOW_USER_ID="True"
        SHOW_TIMESTAMP="True"
    fi
}

show_menu() {
    clear
    echo "================================================"
    echo "           Telegram 机器人管理脚本            "
    echo "================================================"
    echo "1. 安装机器人"
    echo "2. 配置机器人参数"
    echo "3. 查看当前配置"
    echo "4. 启动机器人"
    echo "5. 停止机器人"
    echo "6. 重启机器人"
    echo "7. 查看运行状态"
    echo "8. 查看日志"
    echo "9. 配置线程参数 (建议保持默认)"
    echo "10. 快速配置关键词过滤"
    echo "11. 快速配置隐私保护"
    echo "12. 卸载机器人"
    echo "13. 卸载管理脚本"
    echo "0. 退出脚本"
    echo "================================================"
    
    read -p "请输入您的选择 [0-13]: " choice
}

configure_bot() {
    read_config
    
    while true; do
        clear
        echo "=== 配置机器人参数 ==="
        echo "当前状态："
        echo "------------------------"
        echo "1. BOT_TOKEN:         ${BOT_TOKEN:0:10}***"
        echo "2. ADMIN_USER_ID:     $ADMIN_USER_ID"
        echo "3. 转发目标群组:      $GROUP_CHAT_ID"
        echo "4. 必填频道:          ${REQUIRED_CHANNELS:-无}"
        echo "5. 过滤关键词:        ${FILTER_KEYWORDS:-无}"
        echo "6. 隐私设置:          (用户名:$SHOW_USERNAME / ID:$SHOW_USER_ID / 时间:$SHOW_TIMESTAMP)"
        echo "------------------------"
        echo "7. 保存并退出配置"
        echo "0. 放弃修改并返回主菜单"
        echo ""
        read -p "请输入要修改的选项 [0-7]: " sub_choice

        case $sub_choice in
            1)
                echo ""
                read -p "请输入新的 BOT_TOKEN (回车保持不变): " input
                if [ -n "$input" ]; then
                    BOT_TOKEN="$input"
                    save_config_to_file
                fi
                ;;
            2)
                echo ""
                read -p "请输入新的 ADMIN_USER_ID (回车保持不变): " input
                if [ -n "$input" ]; then
                    ADMIN_USER_ID="$input"
                    save_config_to_file
                fi
                ;;
            3)
                echo ""
                echo "当前转发目标: ${GROUP_CHAT_ID:-无}"
                echo "说明: 多个目标ID用逗号分隔"
                read -p "请输入新的转发目标 ID (回车保持不变): " input
                if [ -n "$input" ]; then
                    GROUP_CHAT_ID="$input"
                    save_config_to_file
                fi
                ;;
            4)
                echo ""
                echo "当前频道: ${REQUIRED_CHANNELS:-无}"
                echo "说明: 多个频道用逗号分隔，输入 CLEAR 清空所有"
                read -p "请输入新的 REQUIRED_CHANNELS (回车保持不变): " input
                if [ "$input" == "CLEAR" ]; then
                    REQUIRED_CHANNELS=""
                    save_config_to_file
                elif [ -n "$input" ]; then
                    REQUIRED_CHANNELS="$input"
                    save_config_to_file
                fi
                ;;
            5)
                echo ""
                echo "当前关键词: ${FILTER_KEYWORDS:-无}"
                echo "说明: 多个关键词用逗号分隔，输入 CLEAR 清空所有"
                read -p "请输入新的 FILTER_KEYWORDS (回车保持不变): " input
                if [ "$input" == "CLEAR" ]; then
                    FILTER_KEYWORDS=""
                    save_config_to_file
                elif [ -n "$input" ]; then
                    FILTER_KEYWORDS="$input"
                    save_config_to_file
                fi
                ;;
            6)
                configure_privacy
                ;;
            7)
                save_config_to_file
                echo "正在返回主菜单..."
                sleep 1
                return
                ;;
            0)
                return
                ;;
            *)
                echo "无效选择"
                sleep 1
                ;;
        esac
    done
}

configure_keywords() {
    clear
    echo "=== 快速配置关键词过滤 ==="
    read_config
    
    echo "当前关键词: ${FILTER_KEYWORDS:-无}"
    echo ""
    echo "功能说明:"
    echo "- 包含这些关键词的行将被删除"
    echo "- 多个关键词用逗号分隔"
    echo "- 关键词匹配不区分大小写"
    echo ""
    
    read -p "请输入新的关键词 (直接回车保持原值，输入 CLEAR 清空): " new_keywords
    
    if [ "$new_keywords" == "CLEAR" ]; then
        FILTER_KEYWORDS=""
        echo "已清空关键词"
        save_config_to_file
    elif [ -n "$new_keywords" ]; then
        FILTER_KEYWORDS="$new_keywords"
        save_config_to_file
    else
        echo "未输入内容，保持原值不变。"
    fi
    
    sleep 2
}

configure_privacy() {
    clear
    echo "=== 配置隐私保护 ==="
    read_config
    
    echo "当前隐私保护设置:"
    echo "1. 显示用户名: $SHOW_USERNAME"
    echo "2. 显示用户ID: $SHOW_USER_ID"
    echo "3. 显示时间戳: $SHOW_TIMESTAMP"
    echo ""
    
    read -p "是否修改隐私保护设置？(y/n): " modify
    if [ "$modify" != "y" ] && [ "$modify" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "请选择要修改的选项（输入数字，多个用逗号分隔，如 1,3）:"
    echo "1. 切换 显示用户名"
    echo "2. 切换 显示用户ID" 
    echo "3. 切换 显示时间戳"
    echo "0. 返回"
    echo ""
    
    read -p "请选择: " privacy_choices
    
    IFS=',' read -ra choices <<< "$privacy_choices"
    
    for choice in "${choices[@]}"; do
        case $choice in
            1)
                if [ "$SHOW_USERNAME" = "True" ]; then SHOW_USERNAME="False"; else SHOW_USERNAME="True"; fi
                ;;
            2)
                if [ "$SHOW_USER_ID" = "True" ]; then SHOW_USER_ID="False"; else SHOW_USER_ID="True"; fi
                ;;
            3)
                if [ "$SHOW_TIMESTAMP" = "True" ]; then SHOW_TIMESTAMP="False"; else SHOW_TIMESTAMP="True"; fi
                ;;
        esac
    done
    
    save_config_to_file
    sleep 1
}

configure_threads() {
    clear
    echo "=== 配置线程参数 ==="
    
    if [ -f "$THREAD_CONFIG_FILE" ]; then
        MAX_WORKERS=$(grep "MAX_WORKERS" "$THREAD_CONFIG_FILE" | awk '{print $3}')
        MEDIA_GROUP_DELAY=$(grep "MEDIA_GROUP_DELAY" "$THREAD_CONFIG_FILE" | awk '{print $3}')
    else
        MAX_WORKERS=10
        MEDIA_GROUP_DELAY=3.0
    fi
    
    echo "当前线程配置:"
    echo "1. 最大工作线程数: $MAX_WORKERS (范围: 1-50)"
    echo "2. 媒体组等待时间: $MEDIA_GROUP_DELAY 秒 (建议 2.0-5.0)"
    echo "   (注意: 这是每次收到新图片后的等待时间，自动延时直到图片传完)"
    echo ""
    
    read -p "是否修改线程配置？(y/n): " modify
    if [ "$modify" != "y" ] && [ "$modify" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "请输入新的线程配置值（直接回车保持原值）:"
    
    read -p "最大工作线程数 (1-50): " new_workers
    read -p "媒体组等待时间 (1.0-10.0秒): " new_delay
    
    MAX_WORKERS=${new_workers:-$MAX_WORKERS}
    MEDIA_GROUP_DELAY=${new_delay:-$MEDIA_GROUP_DELAY}
    
    if ! [[ "$MAX_WORKERS" =~ ^[0-9]+$ ]] || [ "$MAX_WORKERS" -lt 1 ] || [ "$MAX_WORKERS" -gt 50 ]; then
        echo "❌ 最大工作线程数必须是 1-50 之间的整数"
        sleep 2
        return 1
    fi
    
    if ! [[ "$MEDIA_GROUP_DELAY" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$MEDIA_GROUP_DELAY < 1.0" | bc -l) )) || (( $(echo "$MEDIA_GROUP_DELAY > 10.0" | bc -l) )); then
        echo "❌ 媒体组等待时间必须是 1.0-10.0 之间的数字"
        sleep 2
        return 1
    fi
    
    mkdir -p "$(dirname "$THREAD_CONFIG_FILE")"
    
    cat > "$THREAD_CONFIG_FILE" << EOL
MAX_WORKERS = $MAX_WORKERS
MEDIA_GROUP_DELAY = $MEDIA_GROUP_DELAY
EOL

    echo ""
    echo "✅ 线程配置已保存到 $THREAD_CONFIG_FILE"
    echo "⚠️  需要重启机器人才能使新配置生效"
    sleep 3
}

view_config() {
    clear
    read_config
    echo "=== 当前配置 ==="
    echo "BOT_TOKEN:        ${BOT_TOKEN:0:10}***"
    echo "ADMIN_USER_ID:    $ADMIN_USER_ID"
    echo "转发目标群组:     $GROUP_CHAT_ID"
    echo "REQUIRED_CHANNELS: ${REQUIRED_CHANNELS}"
    echo "FILTER_KEYWORDS:   ${FILTER_KEYWORDS}"
    echo "隐私 - 用户名:     $SHOW_USERNAME"
    echo "隐私 - 用户ID:     $SHOW_USER_ID"
    echo "隐私 - 时间戳:     $SHOW_TIMESTAMP"
    echo "================="
    echo "配置文件路径: $CONFIG_FILE"
    
    echo ""
    read -p "按回车键返回菜单..."
}

fix_system_issues() {
    echo "修复系统问题..."
    if dpkg -l | grep -q "chrony"; then
        apt-get install -f -y
        dpkg --configure -a
    fi
    apt autoremove -y
    apt update
}

check_and_install_deps() {
    echo "检查并安装系统依赖..."
    local deps=("python3" "python3-pip" "python3-venv" "git" "bc" "tzdata")
    local to_install=()
    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -q "^ii  $dep "; then
            echo "📦 $dep 需要安装"
            to_install+=("$dep")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        apt update
        apt install -y "${to_install[@]}"
    else
        echo "✅ 所有系统依赖已安装"
    fi
}

install_bot() {
    clear
    echo "=== 安装 Telegram 机器人 ==="
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "⚠️  检测到尚未配置参数，请先进行配置。"
        sleep 2
        configure_bot
        read_config
        if [ -z "$BOT_TOKEN" ]; then
            echo "❌ 配置未完成，安装取消"
            sleep 2
            return 1
        fi
    fi
    
    read_config
    
    echo "即将使用以下配置安装:"
    echo "BOT_TOKEN: ***"
    echo "ADMIN_USER_ID: $ADMIN_USER_ID"
    echo "转发目标群组: $GROUP_CHAT_ID"
    echo ""
    
    read -p "确认安装？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return 1
    fi
    
    fix_system_issues
    check_and_install_deps
    
    echo "设置中国时区..."
    timedatectl set-timezone Asia/Shanghai
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    
    echo "创建项目目录..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    echo "创建Python虚拟环境..."
    if [ ! -d "bot-env" ]; then
        python3 -m venv bot-env
    fi
    
    echo "安装Python依赖..."
    source bot-env/bin/activate
    pip install --upgrade pip
    
    pip install python-telegram-bot httpx aiofiles pytz
    
    if ! python3 -c "import sqlite3" &>/dev/null; then
        apt install -y libsqlite3-dev
    fi
    
    deactivate
    
    if [ ! -f "$THREAD_CONFIG_FILE" ]; then
        cat > "$THREAD_CONFIG_FILE" << EOL
MAX_WORKERS = 10
MEDIA_GROUP_DELAY = 3.0
EOL
    fi
    
    echo "创建主程序文件..."
    cat > "$INSTALL_DIR/telegram_bot.py" << 'EOL'
import logging
import sqlite3
import httpx
import asyncio
import aiofiles
from datetime import datetime
import pytz
import time
import uuid
from telegram import Update, InputMediaPhoto, InputMediaVideo, InputMediaDocument, InlineKeyboardMarkup, InlineKeyboardButton
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes, CallbackQueryHandler
from telegram.constants import ParseMode
from telegram.request import HTTPXRequest
import concurrent.futures
import html
import re

from bot_config import BOT_TOKEN, ADMIN_USER_ID, GROUP_CHAT_ID, REQUIRED_CHANNELS, FILTER_KEYWORDS, DATABASE_NAME
from bot_config import SHOW_USERNAME, SHOW_USER_ID, SHOW_TIMESTAMP

china_tz = pytz.timezone('Asia/Shanghai')

try:
    from thread_config import MAX_WORKERS, MEDIA_GROUP_DELAY
except ImportError:
    MAX_WORKERS = 10
    MEDIA_GROUP_DELAY = 3.0

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

BANNED_USERS = set()
RETRY_DELAY = 2
media_groups = {}
failed_tasks = {} # 用于存储转发失败的任务供快捷重试
thread_pool = concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS)

logger.info(f"线程配置: MAX_WORKERS={MAX_WORKERS}, MEDIA_GROUP_DELAY={MEDIA_GROUP_DELAY}")
logger.info(f"过滤关键词: {FILTER_KEYWORDS}")
logger.info(f"隐私保护 - 显示用户名: {SHOW_USERNAME}, 显示用户ID: {SHOW_USER_ID}, 显示时间: {SHOW_TIMESTAMP}")

def get_china_time():
    return datetime.now(china_tz)

def build_user_info(user):
    user_info_parts = []
    
    first_name = html.escape(user.first_name or '未知')
    
    if SHOW_USERNAME:
        if user.username:
            username = html.escape(user.username)
            user_info_parts.append(f"👤 来自用户: {first_name} (@{username})")
        else:
            user_info_parts.append(f"👤 来自用户: {first_name}")
    else:
        user_info_parts.append("👤 来自用户: ***")
    
    if SHOW_USER_ID:
        user_info_parts.append(f"🆔 用户 ID: <code>{user.id}</code>")
    else:
        user_info_parts.append("🆔 用户 ID: <code>***</code>")
    
    if SHOW_TIMESTAMP:
        user_info_parts.append(f"⏰ 时间: {get_china_time().strftime('%Y-%m-%d %H:%M:%S')}")
    else:
        user_info_parts.append("⏰ 时间: ***")
    
    return "\n".join(user_info_parts)

def init_database():
    conn = sqlite3.connect(DATABASE_NAME, timeout=20)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_usage (
            user_id INTEGER PRIMARY KEY,
            username TEXT,
            first_name TEXT,
            last_name TEXT,
            usage_count INTEGER DEFAULT 0,
            first_used TIMESTAMP,
            last_used TIMESTAMP
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS banned_users (
            user_id INTEGER PRIMARY KEY,
            username TEXT,
            first_name TEXT,
            last_name TEXT,
            banned_by INTEGER,
            banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            reason TEXT
        )
    ''')
    conn.commit()
    conn.close()
    load_banned_users()

def load_banned_users():
    global BANNED_USERS
    try:
        conn = sqlite3.connect(DATABASE_NAME, timeout=20)
        cursor = conn.cursor()
        cursor.execute("SELECT user_id FROM banned_users")
        BANNED_USERS = {row[0] for row in cursor.fetchall()}
        conn.close()
        logger.info(f"已加载 {len(BANNED_USERS)} 个被封禁用户")
    except Exception as e:
        logger.error(f"加载封禁用户列表失败: {e}")

def filter_text_content(text):
    if not text or not FILTER_KEYWORDS:
        return text
    
    lines = text.split('\n')
    filtered_lines = []
    
    for line in lines:
        should_keep = True
        for keyword in FILTER_KEYWORDS:
            if keyword.lower() in line.lower():
                should_keep = False
                logger.info(f"过滤掉包含关键词 '{keyword}' 的行: {line[:50]}...")
                break
        
        if should_keep:
            filtered_lines.append(line)
    
    filtered_text = '\n'.join(filtered_lines)
    
    if not filtered_text.strip():
        return None
    
    return filtered_text

def record_user_usage(user_id, username, first_name, last_name):
    conn = sqlite3.connect(DATABASE_NAME, timeout=20)
    cursor = conn.cursor()
    now = get_china_time()
    
    cursor.execute("SELECT usage_count FROM user_usage WHERE user_id = ?", (user_id,))
    user = cursor.fetchone()
    
    if user:
        cursor.execute('''
            UPDATE user_usage 
            SET usage_count = usage_count + 1, 
                last_used = ?,
                username = ?,
                first_name = ?,
                last_name = ?
            WHERE user_id = ?
        ''', (now, username, first_name, last_name, user_id))
    else:
        cursor.execute('''
            INSERT INTO user_usage 
            (user_id, username, first_name, last_name, usage_count, first_used, last_used)
            VALUES (?, ?, ?, ?, 1, ?, ?)
        ''', (user_id, username, first_name, last_name, now, now))
    
    conn.commit()
    conn.close()

def get_user_usage_count(user_id):
    conn = sqlite3.connect(DATABASE_NAME, timeout=20)
    cursor = conn.cursor()
    cursor.execute("SELECT usage_count FROM user_usage WHERE user_id = ?", (user_id,))
    result = cursor.fetchone()
    conn.close()
    return result[0] if result else 0

async def retry_async_operation(operation, *args, **kwargs):
    attempt = 0
    max_retries = 3
    while attempt < max_retries:
        try:
            result = await operation(*args, **kwargs)
            return result, True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Timeout" in error_str or "Network" in error_str or "Connection" in error_str:
                logger.warning(f"网络异常，第 {attempt} 次重试: {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.error(f"操作失败，不再重试: {e}")
                return None, False
    return None, False

async def run_in_threadpool(func, *args, **kwargs):
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(thread_pool, func, *args, **kwargs)

async def is_member_of_channel(user_id, channel_identifier, bot_token):
    if not channel_identifier:
        return True
        
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            url = f"https://api.telegram.org/bot{bot_token}/getChatMember"
            params = {
                "chat_id": channel_identifier,
                "user_id": user_id
            }
            
            async def make_request():
                response = await client.get(url, params=params)
                return response.json()
            
            member_data_result = await retry_async_operation(make_request)
            if member_data_result[1]:
                member_data = member_data_result[0]
                if member_data and member_data.get("ok"):
                    status = member_data["result"]["status"]
                    allowed_statuses = ["member", "administrator", "creator"]
                    logger.info(f"用户 {user_id} 在频道 {channel_identifier} 的状态: {status}")
                    return status in allowed_statuses
                else:
                    logger.warning(f"无法获取成员状态: {member_data}")
                    return False
            else:
                logger.warning(f"获取频道成员信息失败: {channel_identifier}")
                return False
                
    except Exception as e:
        logger.error(f"检查频道成员时出错: {e}")
        return False

async def check_all_channels_membership(user_id, channel_list, bot_token):
    if not channel_list:
        return True, ""
    
    tasks = [is_member_of_channel(user_id, channel.strip(), bot_token) for channel in channel_list if channel.strip()]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    missing_channels = []
    for i, result in enumerate(results):
        if isinstance(result, Exception) or not result:
            missing_channels.append(channel_list[i].strip())
    
    if missing_channels:
        return False, missing_channels
    return True, ""

async def set_bot_commands(application):
    from telegram import BotCommand
    
    commands = [
        BotCommand("start", "开始使用机器人"),
        BotCommand("stats", "查看统计信息（管理员）"),
        BotCommand("ban", "封禁用户（管理员）"),
        BotCommand("unban", "解封用户（管理员）"),
        BotCommand("banned", "查看封禁列表（管理员）"),
        BotCommand("help", "获取帮助信息"),
        BotCommand("myusage", "查看我的使用次数")
    ]
    
    try:
        await application.bot.set_my_commands(commands)
        logger.info("机器人命令设置成功")
    except Exception as e:
        logger.error(f"设置命令时出错: {e}")

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id in BANNED_USERS:
        await update.message.reply_text("❌ 您已被封禁，无法使用此机器人。")
        return
    
    if REQUIRED_CHANNELS:
        is_member, missing_channels = await check_all_channels_membership(user.id, REQUIRED_CHANNELS, BOT_TOKEN)
        if not is_member:
            channels_text = ""
            for channel in missing_channels:
                if channel.startswith('@'):
                    channels_text += f"• {channel}\n"
                else:
                    channels_text += f"• 频道ID: {channel}\n"
            
            await update.message.reply_text(
                f"❌ 抱歉，您需要先加入以下频道才能使用此机器人：\n\n"
                f"{channels_text}\n"
                f"加入后请再次发送 /start 命令。",
                parse_mode=ParseMode.HTML,
                disable_web_page_preview=True
            )
            return
    
    await update.message.reply_text(
        f"你好 {html.escape(user.first_name or '未知')}！\n\n"
        "欢迎使用消息转发机器人！\n"
        "您可以发送：\n"
        "• 文本消息\n"
        "• 图片/照片\n"
        "• 视频\n"
        "• 文件/文档\n"
        "• 语音消息\n"
        "• 贴纸\n\n"
        "所有内容都会转发到指定群组。\n"
        "使用 /help 查看帮助信息\n"
        "使用 /myusage 查看您的使用次数",
        parse_mode=ParseMode.HTML
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    help_text = (
        "🤖 <b>机器人使用帮助</b>\n\n"
        "📝 <b>可用命令:</b>\n"
        "/start - 开始使用机器人\n"
        "/help - 显示此帮助信息\n"
        "/myusage - 查看您的使用次数\n"
        "/stats - 查看统计信息（仅管理员）\n"
        "/ban - 封禁用户（仅管理员）\n"
        "/unban - 解封用户（仅管理员）\n"
        "/banned - 查看封禁列表（仅管理员）\n\n"
        "📤 <b>支持的消息类型:</b>\n"
        "• 文本消息\n"
        "• 图片/照片\n"
        "• 视频\n"
        "• 文件/文档\n"
        "• 语音消息\n"
        "• 贴纸\n\n"
        "⚠️ <b>注意事项:</b>\n"
        "• 所有消息都会转发到管理群组\n"
        "• 请勿发送垃圾信息\n"
        "• 大文件可能无法转发\n\n"
        "如有问题，请联系管理员。"
    )
    
    await update.message.reply_text(help_text, parse_mode=ParseMode.HTML)

async def myusage_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id in BANNED_USERS:
        await update.message.reply_text("❌ 您已被封禁，无法使用此机器人。")
        return
    
    async def get_usage_async():
        try:
            usage_count = await run_in_threadpool(get_user_usage_count, user.id)
            
            first_name_safe = html.escape(user.first_name or '未知')
            
            usage_text = (
                f"📊 <b>您的使用统计</b>\n\n"
                f"👤 用户: {first_name_safe}"
            )
            if user.username:
                username_safe = html.escape(user.username)
                usage_text += f" (@{username_safe})"
            
            usage_text += f"\n🆔 用户 ID: <code>{user.id}</code>"
            usage_text += f"\n📨 发送消息数: <b>{usage_count}</b>"
            
            if usage_count == 0:
                usage_text += "\n\n💡 提示: 您还没有发送过消息，发送任意消息后即可查看统计。"
            elif usage_count < 10:
                usage_text += "\n\n🌟 您是我们的新用户，感谢使用！"
            elif usage_count < 50:
                usage_text += "\n\n👍 您是我们的活跃用户，继续加油！"
            else:
                usage_text += "\n\n🏆 您是我们的忠实用户，非常感谢您的支持！"
            
            await update.message.reply_text(usage_text, parse_mode=ParseMode.HTML)
            
        except Exception as e:
            logger.error(f"获取用户使用次数时出错: {e}")
            await update.message.reply_text("❌ 获取使用统计时出错，请稍后重试。")
    
    asyncio.create_task(get_usage_async())

async def ban_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id != ADMIN_USER_ID:
        await update.message.reply_text("❌ 抱歉，您没有权限执行此命令。")
        return
    
    if not context.args:
        await update.message.reply_text("用法: /ban <用户ID> [原因]\n示例: /ban 123456789 发送垃圾信息")
        return
    
    try:
        target_user_id = int(context.args[0])
        reason = " ".join(context.args[1:]) if len(context.args) > 1 else "无具体原因"
        
        if target_user_id == ADMIN_USER_ID:
            await update.message.reply_text("❌ 不能封禁自己！")
            return
        
        conn = sqlite3.connect(DATABASE_NAME, timeout=20)
        cursor = conn.cursor()
        
        cursor.execute("SELECT username, first_name, last_name FROM user_usage WHERE user_id = ?", (target_user_id,))
        user_data = cursor.fetchone()
        
        username = user_data[0] if user_data else None
        first_name = user_data[1] if user_data else "未知"
        last_name = user_data[2] if user_data else ""
        
        cursor.execute('''
            INSERT OR REPLACE INTO banned_users 
            (user_id, username, first_name, last_name, banned_by, reason)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (target_user_id, username, first_name, last_name, user.id, reason))
        
        conn.commit()
        conn.close()
        
        BANNED_USERS.add(target_user_id)
        
        user_info = f"{first_name} {last_name}".strip()
        if username:
            user_info += f" (@{username})"
        
        await update.message.reply_text(
            f"✅ 用户已封禁\n\n"
            f"用户: {user_info}\n"
            f"ID: {target_user_id}\n"
            f"原因: {reason}\n"
            f"封禁时间: {get_china_time().strftime('%Y-%m-%d %H:%M:%S')}"
        )
        
    except ValueError:
        await update.message.reply_text("❌ 用户ID必须是数字")
    except Exception as e:
        logger.error(f"封禁用户时出错: {e}")
        await update.message.reply_text("❌ 封禁用户时出错")

async def unban_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id != ADMIN_USER_ID:
        await update.message.reply_text("❌ 抱歉，您没有权限执行此命令。")
        return
    
    if not context.args:
        await update.message.reply_text("用法: /unban <用户ID>\n示例: /unban 123456789")
        return
    
    try:
        target_user_id = int(context.args[0])
        
        conn = sqlite3.connect(DATABASE_NAME, timeout=20)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM banned_users WHERE user_id = ?", (target_user_id,))
        conn.commit()
        conn.close()
        
        BANNED_USERS.discard(target_user_id)
        
        await update.message.reply_text(f"✅ 用户 {target_user_id} 已解封")
        
    except ValueError:
        await update.message.reply_text("❌ 用户ID必须是数字")
    except Exception as e:
        logger.error(f"解封用户时出错: {e}")
        await update.message.reply_text("❌ 解封用户时出错")

async def banned_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id != ADMIN_USER_ID:
        await update.message.reply_text("❌ 抱歉，您没有权限执行此命令。")
        return
    
    try:
        conn = sqlite3.connect(DATABASE_NAME, timeout=20)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT user_id, username, first_name, last_name, banned_at, reason 
            FROM banned_users 
            ORDER BY banned_at DESC
        ''')
        banned_users = cursor.fetchall()
        conn.close()
        
        if not banned_users:
            await update.message.reply_text("📝 当前没有封禁用户")
            return
        
        banned_text = "🚫 <b>封禁用户列表</b>\n\n"
        
        for i, (user_id, username, first_name, last_name, banned_at, reason) in enumerate(banned_users, 1):
            user_info = f"{first_name or ''} {last_name or ''}".strip()
            user_info = html.escape(user_info)
            if username:
                user_info += f" (@{html.escape(username)})"
            if not user_info.strip():
                user_info = f"用户 {user_id}"
            
            banned_text += f"{i}. {user_info}\n"
            banned_text += f"   ID: <code>{user_id}</code>\n"
            banned_text += f"   时间: {banned_at}\n"
            reason_safe = html.escape(reason or '无')
            banned_text += f"   原因: {reason_safe}\n\n"
        
        await update.message.reply_text(banned_text, parse_mode=ParseMode.HTML)
        
    except Exception as e:
        logger.error(f"获取封禁列表时出错: {e}")
        await update.message.reply_text("❌ 获取封禁列表时出错")

async def send_media_group_to_channel(media_group_data):
    try:
        media_list = []
        caption = media_group_data.get('caption', '')
        
        if caption and FILTER_KEYWORDS:
            filtered_caption = filter_text_content(caption)
            if filtered_caption is None:
                caption = ""
            else:
                caption = filtered_caption
        
        user_info = media_group_data.get('user_info', '')
        user_info_plain = user_info.replace('<code>', '').replace('</code>', '')
        
        full_caption = user_info_plain
        if caption:
            full_caption += f"\n\n{caption}"
        
        for media_info in media_group_data['media']:
            if media_info['type'] == 'photo':
                media_list.append(InputMediaPhoto(
                    media=media_info['file_id'], 
                    caption=full_caption if len(media_list) == 0 else None
                ))
            elif media_info['type'] == 'video':
                media_list.append(InputMediaVideo(
                    media=media_info['file_id'], 
                    caption=full_caption if len(media_list) == 0 else None
                ))
            elif media_info['type'] == 'document':
                media_list.append(InputMediaDocument(
                    media=media_info['file_id'], 
                    caption=full_caption if len(media_list) == 0 else None
                ))
        
        if media_list:
            all_success = True
            for target_id in GROUP_CHAT_ID:
                attempt = 0
                max_retries = 5
                target_success = False
                while attempt < max_retries:
                    try:
                        result = await media_group_data['bot'].send_media_group(
                            chat_id=target_id,
                            media=media_list
                        )
                        if result:
                            logger.info(f"成功发送媒体组到 {target_id}，包含 {len(media_list)} 个媒体文件 (尝试 {attempt+1})")
                            target_success = True
                            break
                    except Exception as e:
                        error_str = str(e)
                        attempt += 1
                        
                        if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                            wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                            wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                            logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试媒体组 (第 {attempt} 次)")
                            await asyncio.sleep(wait_time)
                        elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Connection" in error_str or "Timeout" in error_str:
                            logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                            await asyncio.sleep(RETRY_DELAY * attempt)
                        else:
                            logger.warning(f"发送媒体组失败 (尝试 {attempt}): {e}")
                            await asyncio.sleep(RETRY_DELAY)
                if not target_success:
                    logger.error(f"发送媒体组到 {target_id} 达到最大重试次数")
                    all_success = False
            return all_success
    except Exception as e:
        logger.error(f"发送媒体组时出错: {e}")
    return False

async def send_message_with_retry(bot, chat_id, text, parse_mode=None):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_message(
                chat_id=chat_id,
                text=text,
                parse_mode=parse_mode
            )
            if result:
                logger.info(f"消息发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def send_photo_with_retry(bot, chat_id, photo, caption=None, parse_mode=None):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_photo(
                chat_id=chat_id,
                photo=photo,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                logger.info(f"图片发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送图片失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def send_video_with_retry(bot, chat_id, video, caption=None, parse_mode=None):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_video(
                chat_id=chat_id,
                video=video,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                logger.info(f"视频发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送视频失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def send_document_with_retry(bot, chat_id, document, caption=None, parse_mode=None):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_document(
                chat_id=chat_id,
                document=document,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                logger.info(f"文档发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送文档失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def send_voice_with_retry(bot, chat_id, voice, caption=None, parse_mode=None):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_voice(
                chat_id=chat_id,
                voice=voice,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                logger.info(f"语音发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送语音失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def send_sticker_with_retry(bot, chat_id, sticker):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_sticker(
                chat_id=chat_id,
                sticker=sticker
            )
            if result:
                logger.info(f"贴纸发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送贴纸失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def send_audio_with_retry(bot, chat_id, audio, caption=None, parse_mode=None):
    attempt = 0
    max_retries = 5
    while attempt < max_retries:
        try:
            result = await bot.send_audio(
                chat_id=chat_id,
                audio=audio,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                logger.info(f"音频发送成功 (尝试 {attempt+1})")
                return True
        except Exception as e:
            error_str = str(e)
            attempt += 1
            if "Flood control" in error_str or "Too Many Requests" in error_str or "Retry in" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                wait_time = int(wait_time_match.group(1)) if wait_time_match else 30
                logger.warning(f"限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            elif "Bad Gateway" in error_str or "ReadError" in error_str or "TimedOut" in error_str or "Network" in error_str or "Timeout" in error_str:
                logger.warning(f"网络/网关异常 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY * attempt)
            else:
                logger.warning(f"发送音频失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)
    return False

async def process_media_group_timer(group_id, chat_id, bot):
    await asyncio.sleep(MEDIA_GROUP_DELAY)
    
    while True:
        if group_id not in media_groups:
            return
            
        now = time.time()
        last_update = media_groups[group_id].get('last_arrival', 0)
        
        elapsed = now - last_update
        
        if elapsed < MEDIA_GROUP_DELAY:
            wait_time = MEDIA_GROUP_DELAY - elapsed
            await asyncio.sleep(wait_time)
        else:
            break
    
    if group_id in media_groups:
        data = media_groups[group_id]
        message_id = data.get('message_id')
        del media_groups[group_id]
        await send_media_group_with_notification(data, chat_id, message_id, bot)

async def handle_private_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.message or update.message.chat.type != "private":
        return
    
    user = update.effective_user
    
    if user.id in BANNED_USERS:
        await update.message.reply_text("❌ 您已被封禁，无法使用此机器人。")
        return
    
    if REQUIRED_CHANNELS:
        is_member, missing_channels = await check_all_channels_membership(user.id, REQUIRED_CHANNELS, BOT_TOKEN)
        if not is_member:
            channels_text = ""
            for channel in missing_channels:
                if channel.startswith('@'):
                    channels_text += f"• {channel}\n"
                else:
                    channels_text += f"• 频道ID: {channel}\n"
            
            await update.message.reply_text(
                f"❌ 抱歉，您需要先加入以下频道才能使用此机器人：\n\n"
                f"{channels_text}\n"
                f"加入后请再次发送消息。",
                parse_mode=ParseMode.HTML,
                disable_web_page_preview=True
            )
            return
    
    message = update.message

    async def record_usage_async():
        await run_in_threadpool(record_user_usage, user.id, user.username, user.first_name, user.last_name)
    
    asyncio.create_task(record_usage_async())
    
    user_info = build_user_info(user)
    
    try:
        if message.media_group_id:
            group_id = message.media_group_id
            current_time = time.time()
            
            if group_id not in media_groups:
                media_groups[group_id] = {
                    'media': [],
                    'caption': message.caption or '',
                    'user_info': user_info,
                    'group_id': group_id,
                    'bot': context.bot,
                    'last_arrival': current_time,
                    'timer_started': False,
                    'message_id': message.message_id
                }
            else:
                media_groups[group_id]['last_arrival'] = current_time
                media_groups[group_id]['message_id'] = message.message_id # 更新为最新的一条
                if message.caption:
                    media_groups[group_id]['caption'] = message.caption
            
            if message.photo:
                file_id = message.photo[-1].file_id
                media_groups[group_id]['media'].append({
                    'type': 'photo',
                    'file_id': file_id
                })
            elif message.video:
                media_groups[group_id]['media'].append({
                    'type': 'video',
                    'file_id': message.video.file_id
                })
            elif message.document:
                media_groups[group_id]['media'].append({
                    'type': 'document',
                    'file_id': message.document.file_id
                })
            
            if not media_groups[group_id]['timer_started']:
                media_groups[group_id]['timer_started'] = True
                asyncio.create_task(process_media_group_timer(group_id, message.chat_id, context.bot))
            
        else:
            if message.text:
                filtered_text = filter_text_content(message.text_html or message.text)
                if filtered_text is None:
                    await update.message.reply_text("❌ 消息内容包含被过滤的关键词，无法转发。")
                    return
                
                full_text = f"{user_info}\n\n{filtered_text}"
                asyncio.create_task(
                    send_message_with_notification(context.bot, GROUP_CHAT_ID, full_text, ParseMode.HTML, message.chat_id, message.message_id, "消息")
                )
            elif message.photo:
                photo = message.photo[-1]
                full_caption = user_info
                if message.caption:
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_photo_with_notification(context.bot, GROUP_CHAT_ID, photo.file_id, full_caption, ParseMode.HTML, message.chat_id, message.message_id, "图片")
                )
            elif message.video:
                full_caption = user_info
                if message.caption:
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_video_with_notification(context.bot, GROUP_CHAT_ID, message.video.file_id, full_caption, ParseMode.HTML, message.chat_id, message.message_id, "视频")
                )
            elif message.document:
                full_caption = user_info
                if message.caption:
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_document_with_notification(context.bot, GROUP_CHAT_ID, message.document.file_id, full_caption, ParseMode.HTML, message.chat_id, message.message_id, "文档")
                )
            elif message.voice:
                full_caption = user_info
                if message.caption:
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_voice_with_notification(context.bot, GROUP_CHAT_ID, message.voice.file_id, full_caption, ParseMode.HTML, message.chat_id, message.message_id, "语音消息")
                )
            elif message.sticker:
                asyncio.create_task(
                    send_message_with_notification(context.bot, GROUP_CHAT_ID, user_info, ParseMode.HTML, message.chat_id, message.message_id, "用户信息")
                )
                asyncio.create_task(
                    send_sticker_with_notification(context.bot, GROUP_CHAT_ID, message.sticker.file_id, message.chat_id, message.message_id, "贴纸")
                )
            elif message.audio:
                full_caption = user_info
                if message.caption:
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_audio_with_notification(context.bot, GROUP_CHAT_ID, message.audio.file_id, full_caption, ParseMode.HTML, message.chat_id, message.message_id, "音频")
                )
        
    except Exception as e:
        logger.error(f"处理消息时出错: {e}")
        asyncio.create_task(
            send_message_with_retry(context.bot, message.chat_id, "❌ 处理消息时发生内部错误，请稍后重试")
        )

async def notify_user(bot, user_chat_id, message_id, success, message_type, task_data):
    """带按钮的引用回复通知模块"""
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        task_id = str(uuid.uuid4())[:8]
        failed_tasks[task_id] = task_data
        
        reply_markup = InlineKeyboardMarkup([[InlineKeyboardButton("🔄 重试执行转发", callback_data=f"retry_{task_id}")]])
        attempt = 0
        while attempt < 3:
            try:
                await bot.send_message(
                    chat_id=user_chat_id,
                    text=f"❌ {message_type}转发失败，请点击下方按钮重试",
                    reply_to_message_id=message_id,
                    reply_markup=reply_markup
                )
                return
            except Exception as e:
                attempt += 1
                await asyncio.sleep(1)
        
        # 兜底通知
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，且无法生成快捷按钮，请手动重新发送。")

async def send_message_with_notification(bot, target_chat_ids, text, parse_mode, user_chat_id, message_id, message_type="消息"):
    success = True
    for target_id in target_chat_ids:
        if not await send_message_with_retry(bot, target_id, text, parse_mode): success = False
    task_data = {'type': 'text', 'text': text, 'parse_mode': parse_mode, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_photo_with_notification(bot, target_chat_ids, photo, caption, parse_mode, user_chat_id, message_id, message_type="图片"):
    success = True
    for target_id in target_chat_ids:
        if not await send_photo_with_retry(bot, target_id, photo, caption, parse_mode): success = False
    task_data = {'type': 'photo', 'file_id': photo, 'caption': caption, 'parse_mode': parse_mode, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_video_with_notification(bot, target_chat_ids, video, caption, parse_mode, user_chat_id, message_id, message_type="视频"):
    success = True
    for target_id in target_chat_ids:
        if not await send_video_with_retry(bot, target_id, video, caption, parse_mode): success = False
    task_data = {'type': 'video', 'file_id': video, 'caption': caption, 'parse_mode': parse_mode, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_document_with_notification(bot, target_chat_ids, document, caption, parse_mode, user_chat_id, message_id, message_type="文档"):
    success = True
    for target_id in target_chat_ids:
        if not await send_document_with_retry(bot, target_id, document, caption, parse_mode): success = False
    task_data = {'type': 'document', 'file_id': document, 'caption': caption, 'parse_mode': parse_mode, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_voice_with_notification(bot, target_chat_ids, voice, caption, parse_mode, user_chat_id, message_id, message_type="语音消息"):
    success = True
    for target_id in target_chat_ids:
        if not await send_voice_with_retry(bot, target_id, voice, caption, parse_mode): success = False
    task_data = {'type': 'voice', 'file_id': voice, 'caption': caption, 'parse_mode': parse_mode, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_sticker_with_notification(bot, target_chat_ids, sticker, user_chat_id, message_id, message_type="贴纸"):
    success = True
    for target_id in target_chat_ids:
        if not await send_sticker_with_retry(bot, target_id, sticker): success = False
    task_data = {'type': 'sticker', 'file_id': sticker, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_audio_with_notification(bot, target_chat_ids, audio, caption, parse_mode, user_chat_id, message_id, message_type="音频"):
    success = True
    for target_id in target_chat_ids:
        if not await send_audio_with_retry(bot, target_id, audio, caption, parse_mode): success = False
    task_data = {'type': 'audio', 'file_id': audio, 'caption': caption, 'parse_mode': parse_mode, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': message_type}
    await notify_user(bot, user_chat_id, message_id, success, message_type, task_data)

async def send_media_group_with_notification(media_group_data, user_chat_id, message_id, bot):
    success = await send_media_group_to_channel(media_group_data)
    task_data = {'type': 'media_group', 'media_group_data': media_group_data, 'user_chat_id': user_chat_id, 'message_id': message_id, 'message_type': '媒体组消息'}
    await notify_user(bot, user_chat_id, message_id, success, '媒体组消息', task_data)

async def handle_retry_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """处理用户点击重试按钮的内联回调逻辑"""
    query = update.callback_query
    data = query.data
    
    if data.startswith('retry_'):
        task_id = data.split('_')[1]
        if task_id in failed_tasks:
            task = failed_tasks[task_id]
            task_type = task['type']
            message_type = task['message_type']
            
            try:
                await query.edit_message_text(f"🔄 正在重新发送 {message_type}...")
            except Exception:
                pass
            
            success = True
            bot = context.bot
            targets = GROUP_CHAT_ID
            
            # 分发重试任务
            for target in targets:
                target_success = False
                if task_type == 'text':
                    target_success = await send_message_with_retry(bot, target, task['text'], task['parse_mode'])
                elif task_type == 'photo':
                    target_success = await send_photo_with_retry(bot, target, task['file_id'], task['caption'], task['parse_mode'])
                elif task_type == 'video':
                    target_success = await send_video_with_retry(bot, target, task['file_id'], task['caption'], task['parse_mode'])
                elif task_type == 'document':
                    target_success = await send_document_with_retry(bot, target, task['file_id'], task['caption'], task['parse_mode'])
                elif task_type == 'voice':
                    target_success = await send_voice_with_retry(bot, target, task['file_id'], task['caption'], task['parse_mode'])
                elif task_type == 'sticker':
                    target_success = await send_sticker_with_retry(bot, target, task['file_id'])
                elif task_type == 'audio':
                    target_success = await send_audio_with_retry(bot, target, task['file_id'], task['caption'], task['parse_mode'])
                elif task_type == 'media_group':
                    target_success = await send_media_group_to_channel(task['media_group_data'])
                if not target_success:
                    success = False
            
            if success:
                try:
                    await query.edit_message_text(f"✅ 重试成功！您的{message_type}已成功转发到群组！")
                except Exception:
                    pass
                del failed_tasks[task_id]
            else:
                reply_markup = InlineKeyboardMarkup([[InlineKeyboardButton("🔄 再次重试", callback_data=f"retry_{task_id}")]])
                try:
                    await query.edit_message_text(f"❌ 依然失败，{message_type}转发异常，请稍后再次重试", reply_markup=reply_markup)
                except Exception:
                    pass
        else:
            try:
                await query.edit_message_text("❌ 该重试任务已过期或失效（可能是机器人已重启），请您直接重新发送您的原消息。")
            except Exception:
                pass
        
        try:
            await query.answer()
        except Exception:
            pass

async def stats_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id != ADMIN_USER_ID:
        await update.message.reply_text("❌ 抱歉，您没有权限执行此命令。")
        return
    
    async def get_stats():
        conn = sqlite3.connect(DATABASE_NAME, timeout=20)
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM user_usage")
        total_users = cursor.fetchone()[0]
        
        cursor.execute("SELECT SUM(usage_count) FROM user_usage")
        total_messages = cursor.fetchone()[0] or 0
        
        cursor.execute("SELECT COUNT(*) FROM banned_users")
        total_banned = cursor.fetchone()[0]
        
        cursor.execute("SELECT username, first_name, last_name, usage_count FROM user_usage ORDER BY usage_count DESC LIMIT 5")
        top_users = cursor.fetchall()
        
        conn.close()
        
        stats_text = f"🤖 <b>机器人统计信息</b>\n\n"
        stats_text += f"👥 总用户数: <code>{total_users}</code>\n"
        stats_text += f"📨 总消息数: <code>{total_messages}</code>\n"
        stats_text += f"🚫 封禁用户: <code>{total_banned}</code>\n\n"
        stats_text += f"🏆 <b>Top 5 活跃用户:</b>\n"
        
        for i, (username, first_name, last_name, usage_count) in enumerate(top_users, 1):
            display_name = f"{first_name or ''} {last_name or ''}".strip()
            display_name = html.escape(display_name)
            if username:
                display_name += f" (@{html.escape(username)})"
            if not display_name.strip():
                display_name = f"用户 {username}"
            stats_text += f"{i}. {display_name}: {usage_count} 次\n"
        
        await update.message.reply_text(stats_text, parse_mode=ParseMode.HTML)
    
    asyncio.create_task(get_stats())

async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    logger.error(f"机器人错误: {context.error}")
    error_str = str(context.error)
    
    # 忽略一些常见瞬间网络错误直接发给管理员，防止刷屏
    ignore_errors = ["Bad Gateway", "ReadError", "TimedOut", "Timeout", "NetworkError", "httpx", "Connection"]
    if any(err in error_str for err in ignore_errors):
        return
        
    try:
        error_message = f"⚠️ 机器人错误:\n{context.error}"
        await context.bot.send_message(chat_id=ADMIN_USER_ID, text=error_message)
    except Exception as e:
        logger.error(f"发送错误报告失败: {e}")

def main():
    init_database()
    
    # 延长请求池的响应与连接缓冲超时
    request_kwargs = HTTPXRequest(
        connection_pool_size=20,
        read_timeout=120.0,
        write_timeout=120.0,
        connect_timeout=60.0,
        pool_timeout=60.0
    )

    application = Application.builder().token(BOT_TOKEN).request(request_kwargs).build()
    
    application.add_handler(CommandHandler("start", start_command))
    application.add_handler(CommandHandler("stats", stats_command))
    application.add_handler(CommandHandler("ban", ban_command))
    application.add_handler(CommandHandler("unban", unban_command))
    application.add_handler(CommandHandler("banned", banned_command))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("myusage", myusage_command))
    
    # 注册回调处理函数（对应重试按钮）
    application.add_handler(CallbackQueryHandler(handle_retry_callback))
    
    application.add_handler(MessageHandler(
        filters.ChatType.PRIVATE & ~filters.COMMAND,
        handle_private_message
    ))
    
    application.add_error_handler(error_handler)
    
    application.post_init = set_bot_commands
    
    logger.info("🤖 机器人启动中...")
    print("🤖 机器人已启动！按 Ctrl+C 停止")
    
    try:
        application.run_polling(allowed_updates=Update.ALL_TYPES)
    except Exception as e:
        logger.error(f"机器人运行错误: {e}")
        print(f"机器人运行错误: {e}")
    finally:
        thread_pool.shutdown(wait=True)

if __name__ == "__main__":
    main()
EOL

    echo "创建启动脚本..."
    cat > "$INSTALL_DIR/start_bot.sh" << 'EOL'
#!/bin/bash
cd /root/telegram-bot
source /root/telegram-bot/bot-env/bin/activate
python /root/telegram-bot/telegram_bot.py
EOL

    chmod +x "$INSTALL_DIR/start_bot.sh"

    echo "创建系统服务..."
    cat > /tmp/telegram-bot.service << EOL
[Unit]
Description=Telegram Message Forwarding Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/telegram-bot
ExecStart=/root/telegram-bot/start_bot.sh
Restart=always
RestartSec=5
Environment=PATH=/root/telegram-bot/bot-env/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=TZ=Asia/Shanghai

[Install]
WantedBy=multi-user.target
EOL

    mv /tmp/telegram-bot.service "$SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable telegram-bot

    echo "安装完成！"
    echo "使用命令启动: systemctl start telegram-bot"
    sleep 3
}

start_service() {
    clear
    echo "=== 启动机器人 ==="
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "请先安装和配置机器人!"
        sleep 2
        return 1
    fi
    
    systemctl start telegram-bot
    sleep 2
    
    if systemctl is-active --quiet telegram-bot; then
        echo "机器人启动成功!"
    else
        echo "机器人启动失败!"
        echo "查看日志: journalctl -u telegram-bot -n 20"
    fi
    
    sleep 2
}

stop_service() {
    clear
    echo "=== 停止机器人 ==="
    
    systemctl stop telegram-bot
    sleep 2
    
    if systemctl is-active --quiet telegram-bot; then
        echo "停止失败!"
    else
        echo "机器人已停止!"
    fi
    
    sleep 2
}

restart_service() {
    clear
    echo "=== 重启机器人 ==="
    
    systemctl restart telegram-bot
    sleep 2
    
    if systemctl is-active --quiet telegram-bot; then
        echo "重启成功!"
    else
        echo "重启失败!"
    fi
    
    sleep 2
}

view_status() {
    clear
    echo "=== 机器人状态 ==="
    systemctl status telegram-bot --no-pager -l
    echo ""
    read -p "按回车键返回菜单..."
}

view_logs() {
    clear
    echo "=== 查看日志 ==="
    echo "1. 查看最近20条日志"
    echo "2. 实时查看日志"
    echo "3. 查看错误日志"
    echo "0. 返回主菜单"
    echo ""
    
    read -p "请选择: " log_choice
    
    case $log_choice in
        1)
            echo "最近20条日志:"
            journalctl -u telegram-bot -n 20 --no-pager
            ;;
        2)
            echo "开始实时查看日志 (按 Ctrl+C 退出)..."
            journalctl -u telegram-bot -f
            ;;
        3)
            echo "错误日志:"
            journalctl -u telegram-bot --since "1 hour ago" -p err --no-pager
            ;;
        0)
            return
            ;;
        *)
            echo "无效选择"
            ;;
    esac
    
    echo ""
    read -p "按回车键返回菜单..."
}

uninstall_bot() {
    clear
    echo "=== 卸载机器人 ==="
    
    read -p "确定要卸载机器人吗？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return 1
    fi
    
    echo "停止服务..."
    systemctl stop telegram-bot 2>/dev/null
    systemctl disable telegram-bot 2>/dev/null
    
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    
    pkill -f "telegram_bot.py" 2>/dev/null || true
    pkill -f "start_bot.sh" 2>/dev/null || true
    
    read -p "是否删除项目目录和配置？(y/n): " delete_files
    if [ "$delete_files" = "y" ] || [ "$delete_files" = "Y" ]; then
        rm -rf "$INSTALL_DIR"
        echo "项目目录已删除"
    fi
    
    echo "卸载完成!"
    sleep 2
}

uninstall_manager() {
    clear
    echo "=== 卸载管理脚本 ==="
    echo "这将删除管理脚本本身，但不会影响已安装的机器人。"
    read -p "确定要卸载管理脚本吗？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return 1
    fi
    
    if [ -f ~/.bashrc ]; then
        sed -i '/alias botm=/d' ~/.bashrc
    fi
    
    if [ -f "$SCRIPT_FILE" ]; then
        rm -f "$SCRIPT_FILE"
        echo "已删除管理脚本: $SCRIPT_FILE"
    fi
    
    exit 0
}

main() {
    while true; do
        show_menu
        
        case $choice in
            1) install_bot ;;
            2) configure_bot ;;
            3) view_config ;;
            4) start_service ;;
            5) stop_service ;;
            6) restart_service ;;
            7) view_status ;;
            8) view_logs ;;
            9) configure_threads ;;
            10) configure_keywords ;;
            11) configure_privacy ;;
            12) uninstall_bot ;;
            13) uninstall_manager ;;
            0)
                echo "再见！"
                exit 0
                ;;
            *)
                echo "无效选择，请重新输入"
                sleep 2
                ;;
        esac
    done
}

if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

main
