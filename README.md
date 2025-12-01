# Tgbot消息转发🤖️


**[English](./README_EN.md)**


注意：支持Debian/Ubuntu系统


## 一键命令
1. 使用 wget（推荐，Linux 系统自带）
```bash
wget https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/main/bot_manager.sh && chmod +x bot_manager.sh && ./bot_manager.sh
```
2. 使用 curl（若系统无 wget 可用）
```bash
curl -O https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/main/bot_manager.sh && chmod +x bot_manager.sh && ./bot_manager.sh
```


# 预览：
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/refs/heads/main/IMG_5591.jpeg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/refs/heads/main/IMG_5591.jpeg">
  <img alt="自定义图片" src="https://raw.githubusercontent.com/sxxsoo/TG-Forward-bot/refs/heads/main/IMG_5591.jpeg">
</picture>

**补充**

脚本新增功能
增加脚本线程，拒绝报错，管理员封禁权限，用户查询次数权限


#2025.11.26 修复转发失败推送成功问题，因为tg的api限制，增加发送重试


新增功能：删除包含关键词的行


新增功能：用户隐私保护（可分别控制用户名、用户ID、时间的显示）


#2025.11.27 修复重复发送问题：


优化媒体组处理


引入 HTTPXRequest,time 模块


#2025.11.28 修改配置逻辑，解决关键词清空，增加配置子菜单


## 同步上游（Sync Upstream）


**使用方法（ Fork 后）**
1. Fork 本仓库。  
2. 进入你的 Fork → Actions → 找到 `Sync from upstream` 工作流 → Enable workflow。  
3. 首次需要手动同步：点击 **Run workflow**。  
4. 自动同步：工作流会按 cron 每天自动运行一次（默认 UTC 03:00）。  

如需自定义cron，请编辑 `.github/workflows/sync.yml`。


## 介绍


用户使用bot，发送任意内容，bot识别后均可识别转发到指定的群组(可以添加绑定群组变量，添加后用户必须关注频道 ID/用户名 才可使用）


❗️❗️❗️（绑定群组需要设置为管理员）


1. 管理员可以使用 /stats 命令查看前五名用户的使用次数

2. 封禁权限 /ban


（1） 用法: /ban <用户ID> [原因]


（2） 示例: /ban 123456789 发送垃圾信息


3. 解除封禁 /unban


（1） 用法: /unban <用户ID>


（2） 示例: /unban 123456789


4. 查看封禁列表 /banned


5. 用户可以使用 /myusage 命令查看使用次数


## ✨使用教程


管理员下载好 .sh 脚本，上传至服务器


**1.给执行权限**：
```bash
chmod +x bot_manager.sh
```


**2.运行脚本**：
```bash
./bot_manager.sh
```


**3.进去菜单，选择2配置参数**：
  1. 通过 @BotFather 创建一个新的 Telegram 机器人，获取 BOT_TOKEN
  2. 获取您的用户 ID（可以使用 @userinfobot）
  3. 获取目标群组的 ID（超级群组，ID 以 -100 开头）
  4. 频道绑定 ID/用户名


***编辑以下变量：***


· BOT_TOKEN: 您的机器人令牌


· ADMIN_USER_ID: 您的用户 ID


· GROUP_CHAT_ID: 目标群组的 ID


· REQUIRED_CHANNELS 频道绑定 ID/用户名（可选） 


| **变量名**                  | **说明**   | **示例**                                        
|-----------------------------|------------|--------------------------------------------------------------------------|
| `BOT_TOKEN`             | 从 @BotFather 获取    | `123456:ABC-DEF1234ghIkl`    |
| `ADMIN_USER_ID`               | 管理员用户ID   |  `123456789`     |
| `GROUP_CHAT_ID`       | 接受消息群组ID   | `-100123456789`            |
| `REQUIRED_CHANNELS`       | 用户必须加入的频道才可以使用bot（可选）功能：频道群组绑定，用户未关注无法使用   | `@channel1,-100123456789`            |



**4.配置完成后选择1安装机器人**


**5.安装完成选择启动机器人，转发服务即可启动**


⬇️⬇️⬇️


## 支持所有媒体类型


· ✅ 文本消息


· ✅ 图片/照片


· ✅ 视频


· ✅ 文件/文档


· ✅ 语音消息


· ✅ 贴纸


· ✅ 音频文件



## 依赖

```bash
python-telegram-bot 22.5
```

