#!/bin/bash
# Telegram 机器人转发消息pro

 
# 用户使用bot，发送任意内容，bot识别后均可识别转发到指定的群组(可以添加绑定群组变量，添加后用户必须关注频道 ID/用户名 才可使用）
# 参数介绍
# BOT_TOKEN 从 @BotFather 获取 123456:ABC-DEF...
# ADMIN_USER_ID 管理员用户ID 123456789
# GROUP_CHAT_ID 接收消息的群组ID -1001234567890
# REQUIRED_CHANNELS 用户必须加入的频道（可选） @channel1,-100123456789
# 多个频道用英文逗号分隔，支持 @用户名 和 -100 开头的ID格式。
# 增加线程控制，可根据自己服务器选择9进行调节
# 2025.11.26 修复转发失败推送成功问题，因为tg的api限制，增加发送重试
# 新增功能：删除包含关键词所在行

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
    echo "9. 配置线程参数"
    echo "10. 配置关键词过滤"
    echo "11. 卸载机器人"
    echo "12. 卸载管理脚本"
    echo "0. 退出脚本"
    echo "================================================"
    
    read -p "请输入您的选择 [0-12]: " choice
}

read_config() {
    if [ -f "$CONFIG_FILE" ]; then
        BOT_TOKEN=$(grep "BOT_TOKEN" "$CONFIG_FILE" | awk -F'"' '{print $2}')
        ADMIN_USER_ID=$(grep "ADMIN_USER_ID" "$CONFIG_FILE" | awk '{print $3}')
        GROUP_CHAT_ID=$(grep "GROUP_CHAT_ID" "$CONFIG_FILE" | awk '{print $3}')
        
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
    else
        BOT_TOKEN=""
        ADMIN_USER_ID=""
        GROUP_CHAT_ID=""
        REQUIRED_CHANNELS=""
        FILTER_KEYWORDS=""
    fi
}

configure_bot() {
    clear
    echo "=== 配置机器人参数 ==="
    
    read_config
    
    echo "当前配置:"
    echo "1. BOT_TOKEN: ${BOT_TOKEN:0:10}***"
    echo "2. ADMIN_USER_ID: $ADMIN_USER_ID"
    echo "3. GROUP_CHAT_ID: $GROUP_CHAT_ID"
    echo "4. REQUIRED_CHANNELS: ${REQUIRED_CHANNELS:-无}"
    echo "5. FILTER_KEYWORDS: ${FILTER_KEYWORDS:-无}"
    echo ""
    
    read -p "是否修改配置？(y/n): " modify
    if [ "$modify" != "y" ] && [ "$modify" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "请输入新的配置值（直接回车保持原值）:"
    
    read -p "BOT_TOKEN: " new_token
    read -p "ADMIN_USER_ID: " new_admin_id
    read -p "GROUP_CHAT_ID: " new_group_id
    
    echo ""
    echo "必填频道（用逗号分隔，如 @channel1,-1001234567890）"
    read -p "REQUIRED_CHANNELS: " new_channels
    
    echo ""
    echo "过滤关键词（用逗号分隔，包含这些关键词的行将被删除）"
    read -p "FILTER_KEYWORDS: " new_keywords
    
    BOT_TOKEN=${new_token:-$BOT_TOKEN}
    ADMIN_USER_ID=${new_admin_id:-$ADMIN_USER_ID}
    GROUP_CHAT_ID=${new_group_id:-$GROUP_CHAT_ID}
    
    if [ -n "$new_channels" ]; then
        IFS=',' read -ra channel_array <<< "$new_channels"
        channels_python="["
        for i in "${!channel_array[@]}"; do
            if [ $i -ne 0 ]; then
                channels_python+=", "
            fi
            channels_python+="'${channel_array[$i]}'"
        done
        channels_python+="]"
    else
        channels_python="[]"
    fi
    
    if [ -n "$new_keywords" ]; then
        IFS=',' read -ra keyword_array <<< "$new_keywords"
        keywords_python="["
        for i in "${!keyword_array[@]}"; do
            if [ $i -ne 0 ]; then
                keywords_python+=", "
            fi
            keywords_python+="'${keyword_array[$i]}'"
        done
        keywords_python+="]"
    else
        keywords_python="[]"
    fi
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOL
# Telegram Bot 配置文件
BOT_TOKEN = "$BOT_TOKEN"
ADMIN_USER_ID = $ADMIN_USER_ID
GROUP_CHAT_ID = $GROUP_CHAT_ID
REQUIRED_CHANNELS = $channels_python
FILTER_KEYWORDS = $keywords_python
DATABASE_NAME = "bot_database.db"
EOL

    echo ""
    echo "✅ 配置已保存到 $CONFIG_FILE"
    echo ""
    echo "新配置:"
    echo "BOT_TOKEN: ${BOT_TOKEN:0:10}***"
    echo "ADMIN_USER_ID: $ADMIN_USER_ID"
    echo "GROUP_CHAT_ID: $GROUP_CHAT_ID"
    echo "REQUIRED_CHANNELS: $channels_python"
    echo "FILTER_KEYWORDS: $keywords_python"
    
    sleep 3
}

configure_keywords() {
    clear
    echo "=== 配置关键词过滤 ==="
    
    read_config
    
    echo "当前关键词: ${FILTER_KEYWORDS:-无}"
    echo ""
    echo "功能说明:"
    echo "- 包含这些关键词的行将被删除"
    echo "- 多个关键词用逗号分隔"
    echo "- 关键词匹配不区分大小写"
    echo ""
    
    read -p "请输入新的关键词（直接回车清空）: " new_keywords
    
    if [ -n "$new_keywords" ]; then
        IFS=',' read -ra keyword_array <<< "$new_keywords"
        keywords_python="["
        for i in "${!keyword_array[@]}"; do
            if [ $i -ne 0 ]; then
                keywords_python+=", "
            fi
            keywords_python+="'${keyword_array[$i]}'"
        done
        keywords_python+="]"
    else
        keywords_python="[]"
    fi
    
    # 更新配置文件
    if [ -f "$CONFIG_FILE" ]; then
        # 如果存在FILTER_KEYWORDS则更新，否则添加
        if grep -q "FILTER_KEYWORDS" "$CONFIG_FILE"; then
            sed -i "s/FILTER_KEYWORDS = .*/FILTER_KEYWORDS = $keywords_python/" "$CONFIG_FILE"
        else
            # 在REQUIRED_CHANNELS行后添加FILTER_KEYWORDS
            sed -i "/REQUIRED_CHANNELS = /a FILTER_KEYWORDS = $keywords_python" "$CONFIG_FILE"
        fi
    else
        echo "❌ 配置文件不存在，请先配置机器人参数"
        sleep 2
        return 1
    fi
    
    echo ""
    echo "✅ 关键词配置已保存"
    echo "新关键词: $keywords_python"
    
    sleep 3
}

configure_threads() {
    clear
    echo "=== 配置线程参数 ==="
    
    # 读取当前线程配置
    if [ -f "$THREAD_CONFIG_FILE" ]; then
        MAX_WORKERS=$(grep "MAX_WORKERS" "$THREAD_CONFIG_FILE" | awk '{print $3}')
        MEDIA_GROUP_DELAY=$(grep "MEDIA_GROUP_DELAY" "$THREAD_CONFIG_FILE" | awk '{print $3}')
    else
        MAX_WORKERS=10
        MEDIA_GROUP_DELAY=1.5
    fi
    
    echo "当前线程配置:"
    echo "1. 最大工作线程数: $MAX_WORKERS (范围: 1-50)"
    echo "2. 媒体组等待时间: $MEDIA_GROUP_DELAY 秒 (范围: 0.5-5.0)"
    echo ""
    
    read -p "是否修改线程配置？(y/n): " modify
    if [ "$modify" != "y" ] && [ "$modify" != "Y" ]; then
        return
    fi
    
    echo ""
    echo "请输入新的线程配置值（直接回车保持原值）:"
    
    read -p "最大工作线程数 (1-50): " new_workers
    read -p "媒体组等待时间 (0.5-5.0秒): " new_delay
    
    MAX_WORKERS=${new_workers:-$MAX_WORKERS}
    MEDIA_GROUP_DELAY=${new_delay:-$MEDIA_GROUP_DELAY}
    
    # 验证输入
    if ! [[ "$MAX_WORKERS" =~ ^[0-9]+$ ]] || [ "$MAX_WORKERS" -lt 1 ] || [ "$MAX_WORKERS" -gt 50 ]; then
        echo "❌ 最大工作线程数必须是 1-50 之间的整数"
        sleep 2
        return 1
    fi
    
    if ! [[ "$MEDIA_GROUP_DELAY" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$MEDIA_GROUP_DELAY < 0.5" | bc -l) )) || (( $(echo "$MEDIA_GROUP_DELAY > 5.0" | bc -l) )); then
        echo "❌ 媒体组等待时间必须是 0.5-5.0 之间的数字"
        sleep 2
        return 1
    fi
    
    mkdir -p "$(dirname "$THREAD_CONFIG_FILE")"
    
    cat > "$THREAD_CONFIG_FILE" << EOL
# 线程配置
MAX_WORKERS = $MAX_WORKERS
MEDIA_GROUP_DELAY = $MEDIA_GROUP_DELAY
EOL

    echo ""
    echo "✅ 线程配置已保存到 $THREAD_CONFIG_FILE"
    echo ""
    echo "新配置:"
    echo "最大工作线程数: $MAX_WORKERS"
    echo "媒体组等待时间: $MEDIA_GROUP_DELAY 秒"
    echo ""
    echo "⚠️  需要重启机器人才能使新配置生效"
    
    sleep 3
}

view_config() {
    clear
    echo "=== 当前配置 ==="
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "配置文件: $CONFIG_FILE"
        echo ""
        cat "$CONFIG_FILE"
    else
        echo "❌ 配置文件不存在"
        echo "请先运行配置选项"
    fi
    
    echo ""
    echo "=== 线程配置 ==="
    if [ -f "$THREAD_CONFIG_FILE" ]; then
        cat "$THREAD_CONFIG_FILE"
        echo ""
        echo "线程参数范围:"
        echo "- 最大工作线程数: 1-50"
        echo "- 媒体组等待时间: 0.5-5.0秒"
    else
        echo "使用默认线程配置"
        echo "MAX_WORKERS = 10"
        echo "MEDIA_GROUP_DELAY = 1.5"
        echo ""
        echo "线程参数范围:"
        echo "- 最大工作线程数: 1-50"
        echo "- 媒体组等待时间: 0.5-5.0秒"
    fi
    
    echo ""
    read -p "按回车键返回菜单..."
}

fix_system_issues() {
    echo "修复系统问题..."
    
    # 修复dpkg错误
    if dpkg -l | grep -q "chrony"; then
        echo "修复chrony包配置问题..."
        apt-get install -f -y
        dpkg --configure -a
    fi
    
    # 清理不需要的包
    echo "清理不需要的包..."
    apt autoremove -y
    
    # 更新系统
    echo "更新系统包..."
    apt update
    apt upgrade -y
}

check_and_install_deps() {
    echo "检查并安装系统依赖..."
    
    # 定义依赖包列表
    local deps=("python3" "python3-pip" "python3-venv" "git" "bc" "tzdata")
    local to_install=()
    
    # 检查哪些包需要安装
    for dep in "${deps[@]}"; do
        if dpkg -l | grep -q "^ii  $dep "; then
            echo "✅ $dep 已安装"
        else
            echo "📦 $dep 需要安装"
            to_install+=("$dep")
        fi
    done
    
    # 安装缺失的包
    if [ ${#to_install[@]} -gt 0 ]; then
        echo "安装缺失的依赖包: ${to_install[*]}"
        apt update
        apt install -y "${to_install[@]}"
        echo "✅ 所有依赖包安装完成"
    else
        echo "✅ 所有系统依赖已安装"
    fi
}

install_bot() {
    clear
    echo "=== 安装 Telegram 机器人 ==="
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "请先配置机器人参数!"
        sleep 2
        configure_bot
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "配置未完成，安装取消"
            sleep 2
            return 1
        fi
    fi
    
    read_config
    
    echo "即将使用以下配置安装:"
    echo "BOT_TOKEN: ***"
    echo "ADMIN_USER_ID: $ADMIN_USER_ID"
    echo "GROUP_CHAT_ID: $GROUP_CHAT_ID"
    echo "REQUIRED_CHANNELS: ${REQUIRED_CHANNELS:-无}"
    echo "FILTER_KEYWORDS: ${FILTER_KEYWORDS:-无}"
    echo ""
    
    read -p "确认安装？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "安装取消"
        sleep 2
        return 1
    fi
    
    # 修复系统问题
    fix_system_issues
    
    # 检查并安装系统依赖
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
        echo "✅ Python虚拟环境创建成功"
    else
        echo "✅ Python虚拟环境已存在"
    fi
    
    echo "安装Python依赖..."
    source bot-env/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 定义Python依赖
    local python_deps=("python-telegram-bot" "httpx" "aiofiles" "pytz")
    local missing_python_deps=()
    
    # 检查哪些Python依赖需要安装
    for dep in "${python_deps[@]}"; do
        if python -c "import $dep" &>/dev/null 2>&1; then
            echo "✅ $dep 已安装"
        else
            echo "📦 $dep 需要安装"
            missing_python_deps+=("$dep")
        fi
    done
    
    # 安装缺失的Python依赖
    if [ ${#missing_python_deps[@]} -gt 0 ]; then
        echo "安装缺失的Python依赖: ${missing_python_deps[*]}"
        pip install "${missing_python_deps[@]}"
        echo "✅ Python依赖安装完成"
    else
        echo "✅ 所有Python依赖已安装"
    fi
    
    # 验证sqlite3是否可用（Python内置）
    if python3 -c "import sqlite3; print('sqlite3可用')" &>/dev/null; then
        echo "✅ sqlite3模块可用（Python内置）"
    else
        echo "❌ sqlite3模块不可用"
        # 尝试安装系统级的sqlite3开发包
        apt install -y libsqlite3-dev
    fi
    
    deactivate
    
    echo "验证依赖安装..."
    source bot-env/bin/activate
    
    # 最终验证所有依赖
    local all_ok=true
    for dep in telegram httpx aiofiles pytz sqlite3; do
        if python -c "import $dep" &>/dev/null; then
            echo "✅ $dep 可用"
        else
            echo "❌ $dep 不可用"
            all_ok=false
        fi
    done
    
    if $all_ok; then
        echo "✅ 所有依赖安装成功!"
    else
        echo "❌ 部分依赖安装失败，请检查系统环境"
        deactivate
        return 1
    fi
    
    deactivate
    
    echo "创建线程配置文件..."
    if [ ! -f "$THREAD_CONFIG_FILE" ]; then
        cat > "$THREAD_CONFIG_FILE" << EOL
# 线程配置
MAX_WORKERS = 10
MEDIA_GROUP_DELAY = 1.5
EOL
        echo "默认线程配置已创建"
    else
        echo "✅ 线程配置文件已存在"
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
from telegram import Update, InputMediaPhoto, InputMediaVideo, InputMediaDocument
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from telegram.constants import ParseMode
import concurrent.futures
import html
import re

from bot_config import BOT_TOKEN, ADMIN_USER_ID, GROUP_CHAT_ID, REQUIRED_CHANNELS, FILTER_KEYWORDS, DATABASE_NAME

# 设置中国时区
china_tz = pytz.timezone('Asia/Shanghai')

# 尝试导入线程配置，如果不存在则使用默认值
try:
    from thread_config import MAX_WORKERS, MEDIA_GROUP_DELAY
except ImportError:
    MAX_WORKERS = 10
    MEDIA_GROUP_DELAY = 1.5

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# 全局变量
BANNED_USERS = set()
RETRY_DELAY = 2
# 存储媒体组的字典
media_groups = {}
# 线程池执行器
thread_pool = concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS)

# 记录线程配置
logger.info(f"线程配置: MAX_WORKERS={MAX_WORKERS}, MEDIA_GROUP_DELAY={MEDIA_GROUP_DELAY}")
logger.info(f"过滤关键词: {FILTER_KEYWORDS}")

def get_china_time():
    """获取中国时区时间"""
    return datetime.now(china_tz)

def init_database():
    conn = sqlite3.connect(DATABASE_NAME)
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
        conn = sqlite3.connect(DATABASE_NAME)
        cursor = conn.cursor()
        cursor.execute("SELECT user_id FROM banned_users")
        BANNED_USERS = {row[0] for row in cursor.fetchall()}
        conn.close()
        logger.info(f"已加载 {len(BANNED_USERS)} 个被封禁用户")
    except Exception as e:
        logger.error(f"加载封禁用户列表失败: {e}")

def filter_text_content(text):
    """过滤文本内容，删除包含关键词的行"""
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
    
    # 如果过滤后文本为空，返回None
    if not filtered_text.strip():
        return None
    
    return filtered_text

def record_user_usage(user_id, username, first_name, last_name):
    conn = sqlite3.connect(DATABASE_NAME)
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
    """获取用户使用次数"""
    conn = sqlite3.connect(DATABASE_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT usage_count FROM user_usage WHERE user_id = ?", (user_id,))
    result = cursor.fetchone()
    conn.close()
    return result[0] if result else 0

async def retry_async_operation(operation, *args, **kwargs):
    """重试异步操作直到成功"""
    attempt = 0
    while True:
        try:
            result = await operation(*args, **kwargs)
            return result, True  # 返回结果和成功状态
        except httpx.ReadError as e:
            attempt += 1
            logger.warning(f"网络错误，第 {attempt} 次重试: {e}")
            await asyncio.sleep(RETRY_DELAY)
        except Exception as e:
            error_str = str(e)
            # 检查是否是Flood控制错误
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                # 从错误消息中提取等待时间
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30  # 默认等待30秒
                
                attempt += 1
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.error(f"操作失败，不重试: {e}")
                return None, False

async def run_in_threadpool(func, *args, **kwargs):
    """在线程池中运行阻塞操作"""
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
            
            # 修复：正确提取retry_async_operation的结果
            member_data_result = await retry_async_operation(make_request)
            if member_data_result[1]:  # 检查操作是否成功
                member_data = member_data_result[0]  # 提取实际数据
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
    
    # 使用多线程并行检查所有频道
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
        f"你好 {user.first_name}！\n\n"
        "欢迎使用消息转发机器人！\n"
        "您可以发送：\n"
        "• 文本消息\n"
        "• 图片/照片\n"
        "• 视频\n"
        "• 文件/文档\n"
        "• 语音消息\n"
        "• 贴纸\n\n"
        "所有内容都会转发到指定群组。\n"
        "此服务由 @sxxsoo 脚本搭建\n\n"
        "使用 /help 查看帮助信息\n"
        "使用 /myusage 查看您的使用次数"
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
    
    # 在后台线程中获取使用次数
    async def get_usage_async():
        try:
            usage_count = await run_in_threadpool(get_user_usage_count, user.id)
            
            usage_text = (
                f"📊 <b>您的使用统计</b>\n\n"
                f"👤 用户: {user.first_name or '未知'}"
            )
            if user.username:
                usage_text += f" (@{user.username})"
            
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
        
        conn = sqlite3.connect(DATABASE_NAME)
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
        
        conn = sqlite3.connect(DATABASE_NAME)
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
        conn = sqlite3.connect(DATABASE_NAME)
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
            if username:
                user_info += f" (@{username})"
            if not user_info.strip():
                user_info = f"用户 {user_id}"
            
            banned_text += f"{i}. {user_info}\n"
            banned_text += f"   ID: <code>{user_id}</code>\n"
            banned_text += f"   时间: {banned_at}\n"
            banned_text += f"   原因: {reason or '无'}\n\n"
        
        await update.message.reply_text(banned_text, parse_mode=ParseMode.HTML)
        
    except Exception as e:
        logger.error(f"获取封禁列表时出错: {e}")
        await update.message.reply_text("❌ 获取封禁列表时出错")

async def send_media_group_to_channel(media_group_data):
    """发送媒体组到目标频道"""
    try:
        media_list = []
        caption = media_group_data.get('caption', '')
        
        # 过滤caption中的关键词
        if caption and FILTER_KEYWORDS:
            filtered_caption = filter_text_content(caption)
            if filtered_caption is None:
                caption = ""  # 如果所有内容都被过滤，caption为空
            else:
                caption = filtered_caption
        
        # 构建完整的caption（用户信息 + 原始caption）
        # 注意：InputMediaPhoto/InputMediaVideo 的 caption 不支持 HTML 解析，只能使用纯文本
        user_info = media_group_data.get('user_info', '')
        
        # 将 HTML 转换为纯文本，移除 <code> 标签
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
            # 媒体组发送无限重试机制
            attempt = 0
            while True:
                try:
                    result = await media_group_data['bot'].send_media_group(
                        chat_id=GROUP_CHAT_ID,
                        media=media_list
                    )
                    if result:
                        attempt += 1
                        logger.info(f"成功发送媒体组，包含 {len(media_list)} 个媒体文件 (尝试 {attempt})")
                        return True
                    else:
                        attempt += 1
                        logger.warning(f"媒体组发送返回空结果 (尝试 {attempt})")
                except Exception as e:
                    error_str = str(e)
                    attempt += 1
                    
                    # 检查是否是Flood控制错误
                    if "Flood control" in error_str or "Too Many Requests" in error_str:
                        # 从错误消息中提取等待时间
                        import re
                        wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                        if wait_time_match:
                            wait_time = int(wait_time_match.group(1))
                        else:
                            wait_time = 30  # 默认等待30秒
                        
                        logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试媒体组 (第 {attempt} 次)")
                        await asyncio.sleep(wait_time)
                    else:
                        logger.warning(f"发送媒体组失败 (尝试 {attempt}): {e}")
                        await asyncio.sleep(RETRY_DELAY)
        
    except Exception as e:
        logger.error(f"发送媒体组时出错: {e}")
    return False

async def send_message_with_retry(bot, chat_id, text, parse_mode=None):
    """带无限重试机制的发送消息函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_message(
                chat_id=chat_id,
                text=text,
                parse_mode=parse_mode
            )
            if result:
                attempt += 1
                logger.info(f"消息发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"消息发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            # 检查是否是Flood控制错误
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                # 从错误消息中提取等待时间
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30  # 默认等待30秒
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试消息 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送消息失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def send_photo_with_retry(bot, chat_id, photo, caption=None, parse_mode=None):
    """带无限重试机制的发送图片函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_photo(
                chat_id=chat_id,
                photo=photo,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                attempt += 1
                logger.info(f"图片发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"图片发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试图片 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送图片失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def send_video_with_retry(bot, chat_id, video, caption=None, parse_mode=None):
    """带无限重试机制的发送视频函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_video(
                chat_id=chat_id,
                video=video,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                attempt += 1
                logger.info(f"视频发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"视频发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试视频 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送视频失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def send_document_with_retry(bot, chat_id, document, caption=None, parse_mode=None):
    """带无限重试机制的发送文档函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_document(
                chat_id=chat_id,
                document=document,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                attempt += 1
                logger.info(f"文档发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"文档发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试文档 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送文档失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def send_voice_with_retry(bot, chat_id, voice, caption=None, parse_mode=None):
    """带无限重试机制的发送语音函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_voice(
                chat_id=chat_id,
                voice=voice,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                attempt += 1
                logger.info(f"语音发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"语音发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试语音 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送语音失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def send_sticker_with_retry(bot, chat_id, sticker):
    """带无限重试机制的发送贴纸函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_sticker(
                chat_id=chat_id,
                sticker=sticker
            )
            if result:
                attempt += 1
                logger.info(f"贴纸发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"贴纸发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试贴纸 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送贴纸失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def send_audio_with_retry(bot, chat_id, audio, caption=None, parse_mode=None):
    """带无限重试机制的发送音频函数"""
    attempt = 0
    while True:
        try:
            result = await bot.send_audio(
                chat_id=chat_id,
                audio=audio,
                caption=caption,
                parse_mode=parse_mode
            )
            if result:
                attempt += 1
                logger.info(f"音频发送成功 (尝试 {attempt})")
                return True
            else:
                attempt += 1
                logger.warning(f"音频发送返回空结果 (尝试 {attempt})")
        except Exception as e:
            error_str = str(e)
            attempt += 1
            
            if "Flood control" in error_str or "Too Many Requests" in error_str:
                wait_time_match = re.search(r'Retry in (\d+) seconds', error_str)
                if wait_time_match:
                    wait_time = int(wait_time_match.group(1))
                else:
                    wait_time = 30
                
                logger.warning(f"Flood控制限制，等待 {wait_time} 秒后重试音频 (第 {attempt} 次)")
                await asyncio.sleep(wait_time)
            else:
                logger.warning(f"发送音频失败 (尝试 {attempt}): {e}")
                await asyncio.sleep(RETRY_DELAY)

async def handle_private_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.message.chat.type != "private":
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

    # 在后台线程中记录用户使用情况，不阻塞主流程
    async def record_usage_async():
        await run_in_threadpool(record_user_usage, user.id, user.username, user.first_name, user.last_name)
    
    asyncio.create_task(record_usage_async())
    
    # 构建用户信息 - 修复ID格式问题
    user_info = f"👤 来自用户: {user.first_name or '未知'}"
    if user.username:
        user_info += f" (@{user.username})"
    user_info += f"\n🆔 用户 ID: <code>{user.id}</code>"
    user_info += f"\n⏰ 时间: {get_china_time().strftime('%Y-%m-%d %H:%M:%S')}"
    
    try:
        # 处理媒体组消息
        if message.media_group_id:
            group_id = message.media_group_id
            
            # 初始化或更新媒体组数据
            if group_id not in media_groups:
                media_groups[group_id] = {
                    'media': [],
                    'caption': message.caption or '',
                    'user_info': user_info,
                    'group_id': group_id,
                    'bot': context.bot,
                    'last_update': message.date
                }
            
            # 添加媒体到组
            if message.photo:
                # 获取最高质量的图片
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
            
            # 设置定时器发送媒体组（使用配置的等待时间）
            if group_id in media_groups:
                await asyncio.sleep(MEDIA_GROUP_DELAY)
                if group_id in media_groups:
                    # 在后台发送媒体组并自动重试
                    asyncio.create_task(send_media_group_with_notification(media_groups[group_id], message.chat_id, context.bot))
                    # 清理已发送的媒体组
                    del media_groups[group_id]
            
        else:
            # 处理单个消息 - 所有内容在一个消息中发送，使用多线程
            if message.text:
                # 纯文本消息 - 过滤关键词
                filtered_text = filter_text_content(message.text_html or message.text)
                if filtered_text is None:
                    # 如果所有内容都被过滤，通知用户
                    await update.message.reply_text("❌ 消息内容包含被过滤的关键词，无法转发。")
                    return
                
                full_text = f"{user_info}\n\n{filtered_text}"
                asyncio.create_task(
                    send_message_with_notification(context.bot, GROUP_CHAT_ID, full_text, ParseMode.HTML, message.chat_id, "消息")
                )
            elif message.photo:
                # 单张图片
                photo = message.photo[-1]
                full_caption = user_info
                if message.caption:
                    # 过滤caption中的关键词
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_photo_with_notification(context.bot, GROUP_CHAT_ID, photo.file_id, full_caption, ParseMode.HTML, message.chat_id, "图片")
                )
            elif message.video:
                # 单个视频
                full_caption = user_info
                if message.caption:
                    # 过滤caption中的关键词
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_video_with_notification(context.bot, GROUP_CHAT_ID, message.video.file_id, full_caption, ParseMode.HTML, message.chat_id, "视频")
                )
            elif message.document:
                # 单个文档
                full_caption = user_info
                if message.caption:
                    # 过滤caption中的关键词
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_document_with_notification(context.bot, GROUP_CHAT_ID, message.document.file_id, full_caption, ParseMode.HTML, message.chat_id, "文档")
                )
            elif message.voice:
                # 语音消息
                full_caption = user_info
                if message.caption:
                    # 过滤caption中的关键词
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_voice_with_notification(context.bot, GROUP_CHAT_ID, message.voice.file_id, full_caption, ParseMode.HTML, message.chat_id, "语音消息")
                )
            elif message.sticker:
                # 贴纸 - 先发送用户信息，再发送贴纸
                asyncio.create_task(
                    send_message_with_notification(context.bot, GROUP_CHAT_ID, user_info, ParseMode.HTML, message.chat_id, "用户信息")
                )
                asyncio.create_task(
                    send_sticker_with_notification(context.bot, GROUP_CHAT_ID, message.sticker.file_id, message.chat_id, "贴纸")
                )
            elif message.audio:
                # 音频文件
                full_caption = user_info
                if message.caption:
                    # 过滤caption中的关键词
                    filtered_caption = filter_text_content(message.caption)
                    if filtered_caption is not None:
                        full_caption += f"\n\n{filtered_caption}"
                
                asyncio.create_task(
                    send_audio_with_notification(context.bot, GROUP_CHAT_ID, message.audio.file_id, full_caption, ParseMode.HTML, message.chat_id, "音频")
                )
        
    except Exception as e:
        logger.error(f"处理消息时出错: {e}")
        asyncio.create_task(
            send_message_with_retry(context.bot, message.chat_id, "❌ 处理消息时发生错误，请稍后重试")
        )

async def send_message_with_notification(bot, target_chat_id, text, parse_mode, user_chat_id, message_type="消息"):
    """发送消息并通知用户结果"""
    success = await send_message_with_retry(bot, target_chat_id, text, parse_mode)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_photo_with_notification(bot, target_chat_id, photo, caption, parse_mode, user_chat_id, message_type="图片"):
    """发送图片并通知用户结果"""
    success = await send_photo_with_retry(bot, target_chat_id, photo, caption, parse_mode)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_video_with_notification(bot, target_chat_id, video, caption, parse_mode, user_chat_id, message_type="视频"):
    """发送视频并通知用户结果"""
    success = await send_video_with_retry(bot, target_chat_id, video, caption, parse_mode)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_document_with_notification(bot, target_chat_id, document, caption, parse_mode, user_chat_id, message_type="文档"):
    """发送文档并通知用户结果"""
    success = await send_document_with_retry(bot, target_chat_id, document, caption, parse_mode)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_voice_with_notification(bot, target_chat_id, voice, caption, parse_mode, user_chat_id, message_type="语音消息"):
    """发送语音并通知用户结果"""
    success = await send_voice_with_retry(bot, target_chat_id, voice, caption, parse_mode)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_sticker_with_notification(bot, target_chat_id, sticker, user_chat_id, message_type="贴纸"):
    """发送贴纸并通知用户结果"""
    success = await send_sticker_with_retry(bot, target_chat_id, sticker)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_audio_with_notification(bot, target_chat_id, audio, caption, parse_mode, user_chat_id, message_type="音频"):
    """发送音频并通知用户结果"""
    success = await send_audio_with_retry(bot, target_chat_id, audio, caption, parse_mode)
    if success:
        await send_message_with_retry(bot, user_chat_id, f"✅ 您的{message_type}已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, f"❌ {message_type}转发失败，请稍后重试")

async def send_media_group_with_notification(media_group_data, user_chat_id, bot):
    """发送媒体组并通知用户结果"""
    success = await send_media_group_to_channel(media_group_data)
    if success:
        await send_message_with_retry(bot, user_chat_id, "✅ 您的媒体组消息已成功转发到群组！")
    else:
        await send_message_with_retry(bot, user_chat_id, "❌ 媒体组消息转发失败，请稍后重试")

async def stats_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    
    if user.id != ADMIN_USER_ID:
        await update.message.reply_text("❌ 抱歉，您没有权限执行此命令。")
        return
    
    # 在后台线程中执行数据库操作
    async def get_stats():
        conn = sqlite3.connect(DATABASE_NAME)
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
            if username:
                display_name += f" (@{username})"
            if not display_name.strip():
                display_name = f"用户 {username}"
            stats_text += f"{i}. {display_name}: {usage_count} 次\n"
        
        await update.message.reply_text(stats_text, parse_mode=ParseMode.HTML)
    
    asyncio.create_task(get_stats())

async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    logger.error(f"机器人错误: {context.error}")
    
    try:
        error_message = f"⚠️ 机器人错误:\n{context.error}"
        await context.bot.send_message(chat_id=ADMIN_USER_ID, text=error_message)
    except Exception as e:
        logger.error(f"发送错误报告失败: {e}")

def main():
    init_database()
    
    application = Application.builder().token(BOT_TOKEN).build()
    
    application.add_handler(CommandHandler("start", start_command))
    application.add_handler(CommandHandler("stats", stats_command))
    application.add_handler(CommandHandler("ban", ban_command))
    application.add_handler(CommandHandler("unban", unban_command))
    application.add_handler(CommandHandler("banned", banned_command))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("myusage", myusage_command))
    
    application.add_handler(MessageHandler(
        filters.ChatType.PRIVATE & (
            filters.TEXT | filters.PHOTO | filters.VIDEO | 
            filters.Document.ALL | filters.VOICE | filters.Sticker.ALL |
            filters.AUDIO
        ),
        handle_private_message
    ))
    
    application.add_error_handler(error_handler)
    
    application.post_init = set_bot_commands
    
    logger.info("🤖 机器人启动中...")
    print("🤖 机器人已启动！按 Ctrl+C 停止")
    
    try:
        application.run_polling(allowed_updates=Update.ALL_TYPES)
    except httpx.ReadError as e:
        logger.error(f"网络连接错误: {e}")
        print("网络连接出现问题，请检查网络后重试")
    except Exception as e:
        logger.error(f"机器人运行错误: {e}")
        print(f"机器人运行错误: {e}")
    finally:
        # 关闭线程池
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
        echo "卸载取消"
        sleep 2
        return 1
    fi
    
    echo "停止服务..."
    systemctl stop telegram-bot 2>/dev/null
    systemctl disable telegram-bot 2>/dev/null
    
    echo "删除服务文件..."
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    
    echo "清理进程..."
    pkill -f "telegram_bot.py" 2>/dev/null || true
    pkill -f "start_bot.sh" 2>/dev/null || true
    
    read -p "是否删除项目目录和配置？(y/n): " delete_files
    if [ "$delete_files" = "y" ] || [ "$delete_files" = "Y" ]; then
        echo "删除项目文件..."
        rm -rf "$INSTALL_DIR"
        echo "项目目录已删除"
    else
        echo "保留项目目录: $INSTALL_DIR"
    fi
    
    echo "卸载完成!"
    sleep 2
}

uninstall_manager() {
    clear
    echo "=== 卸载管理脚本 ==="
    echo ""
    echo "这将删除管理脚本本身，但不会影响已安装的机器人。"
    echo ""
    
    read -p "确定要卸载管理脚本吗？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "卸载取消"
        sleep 2
        return 1
    fi
    
    if [ -f ~/.bashrc ]; then
        sed -i '/alias botm=/d' ~/.bashrc
        echo "已删除alias配置"
    fi
    
    if [ -f "$SCRIPT_FILE" ]; then
        rm -f "$SCRIPT_FILE"
        echo "已删除管理脚本: $SCRIPT_FILE"
    fi
    
    echo ""
    echo "管理脚本已卸载完成！"
    echo "注意：机器人服务仍然存在，如需卸载机器人请先使用选项11"
    sleep 3
    
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
            11) uninstall_bot ;;
            12) uninstall_manager ;;
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
