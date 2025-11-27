# Tgbot Message Forwarding 🤖️

**Note: Supports Debian/Ubuntu systems**

---


## One-Click Commands


1.	wget (Recommended, pre-installed on Linux systems)
```bash
wget https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/main/bot_manager.sh && chmod +x bot_manager.sh && ./bot_manager.sh
```
2.  curl (For systems without wget)
```bash
curl -O https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/main/bot_manager.sh && chmod +x bot_manager.sh && ./bot_manager.sh
```


# Preview:
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/refs/heads/main/IMG_5591.jpeg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/refs/heads/main/IMG_5591.jpeg">
  <img alt="自定义图片" src="https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/refs/heads/main/IMG_5591.jpeg">
</picture>

---

**Update**

Script new features:  
- Added threading to enhance stability and prevent interruption  
- Error-proof execution (no crash on failure)  
- Admin ban/unban permissions  
- User message usage query  

**2025.11.26** — Fixed forwarding failure but push success due to Telegram API limitations. Added retry sending mechanism.

---

## Sync Upstream

**How to use (after Forking)**  
1. Fork this repository.  
2. Go to your Fork → Actions → find `Sync from upstream` workflow → Enable workflow.  
3. First time: click **Run workflow** to sync manually.  
4. Auto sync: Workflow runs daily based on cron (default UTC 03:00).  

To customize cron, edit `.github/workflows/sync.yml`.

---

## Introduction

Users can send any type of content to the bot, and it will automatically forward it to the specified group.  
(Optional) You can set required channel bindings — users must join the specified channel(s) before using the bot.

> The bound group must be set as an **administrator**.

### Admin Commands

| Command | Description |
|---------|-------------|
| `/stats` | View top 5 users by usage count |
| `/ban <user_id> [reason]` | Ban a user |
| `/unban <user_id>` | Unban a user |
| `/banned` | View banned users list |
| `/myusage` | Users check their own usage count |

**Examples:**

/ban 123456789 Spamming
/unban 123456789

---

## ✨ Setup Tutorial

Download the `.sh` script and upload it to your server.

**1. Grant execute permission:**
```bash
chmod +x bot_manager.sh
```


**2. Run the script:**
```bash
./bot_manager.sh
```


**3. Enter menu → Select option 2 to configure parameters:**
1. Create a Telegram bot using @BotFather and get BOT_TOKEN
2. Use @userinfobot to get your user ID
3. Get the target group ID (supergroup, starts with -100)
4. Set channel binding (optional)

Edit the following variables:

	•	BOT_TOKEN: Your bot token

	•	ADMIN_USER_ID: Your user ID

	•	GROUP_CHAT_ID: Target group ID

	•	REQUIRED_CHANNELS: Channel binding ID/username (optional)



| **Variable Name** | **Description** | **Example** |
|-----------------------------|------------|--------------------------------------------------------------------------|
| `BOT_TOKEN` | From @BotFather | `123456:ABC-DEF1234ghIkl` |
| `ADMIN_USER_ID` | Admin user ID | `123456789` |
| `GROUP_CHAT_ID` | Target group chat ID | `-100123456789` |
| `REQUIRED_CHANNELS` | Channels users must join before using the bot (optional): channel-group binding; users who haven’t joined cannot use the bot | `@channel1,-100123456789` |

**4. After configuration, select option 1 to install the bot**

**5. After installation, select Start Bot to enable the forwarding service**


Supported Media Types


· ✅ Text messages


· ✅ Photos / Images


· ✅ Videos


· ✅ Files / Documents


· ✅ Voice messages


· ✅ Stickers


· ✅ Audio files


Server hosting is provided by AuroraCloud — thank you for your support
