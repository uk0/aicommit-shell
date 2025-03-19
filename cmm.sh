#!/bin/bash

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 定义 API 地址和 API 密钥,可以自己自行替换。
api_url="https://api.openai.com/v1/chat/completions"
api_key=$(OPENAI_API_KEY)


# 📝 Get only the diff of what has already been staged
git_diff_output=$(git diff --cached)


# 🛑 Check if there are any staged changes to commit
if [ -z "$git_diff_output" ]; then
  echo "⚠️  No staged changes detected. Aborting."
  exit 1
fi

# 🗜️ Limit the number of lines sent to AI to avoid overwhelming it
git_diff_output_limited=$(echo "$git_diff_output" | head -n 100)

emoji_table="
Emoji	Conventional Commit Type	说明
✨	feat	新功能（feature）
🐛	fix	修复 bug
📝	docs	修改或新增文档
🎨	style	格式变动（不影响代码运行）
♻️	refactor	重构（非新增功能或修复的代码变动）
⚡️	perf	性能优化
✅	test	新增或修改测试用例
🔧	chore	构建过程或辅助工具的变动，或不影响源代码的改动
🚑️	hotfix	紧急修复
🚀	deploy	部署
🔒	security	安全方面的改动
🔀	merge	分支合并
⬆️	upgrade	依赖或版本升级
"

# 定义生成提交信息的请求 JSON 数据

# 然后，使用 jq 来生成 JSON 数据
BODY_DATA=$(jq -n \
  --arg diff "$git_diff_output_limited" \
  --arg emojo "$emoji_table" \
  '{
     "messages": [
       {
         "role": "system",
         "content": "You are an AI assistant that helps generate git commit messages based on code changes\n $emojo."
       },
       {
         "role": "user",
	 "content": ("Suggest an informative commit message by summarizing code changes from the shared command output. The commit message should follow the conventional commit format (emoji+status) and provide meaningful context for future readers.\n\nChanges:\n" + $diff)
       }
     ],
     "temperature": 0.2,
     "max_tokens": 512,
     "top_p": 0.5,
     "frequency_penalty": 0,
     "presence_penalty": 0,
     "model": "gpt-4o-ca",
     "stream": false
   }')

# 使用环境变量的 curl 请求
response=$(curl -s -X --location --request POST $api_url \
--header "Authorization: Bearer $api_key" \
--header "Content-Type: application/json" \
--data-raw "$BODY_DATA")

# 从响应中提取提交信息
commit_msg=$(echo $response |jq -r '.choices[] | select(.message.role=="assistant") | .message.content')

# 输出提交信息
date_str=$(date '+%Y-%m-%d_%H:%M:%S')  # 获取当前日期和时间
file_path="/tmp/.ai_commit_$date_str"  # 创建文件路径
echo "$commit_msg" > $file_path  # 写入 commit 消息到文件

vim $file_path

# 提示用户是否使用这个文件进行提交
echo -e "\033[32mGenerating commit message...\033[0m"
echo -e "\033[1;37m$(cat $file_path)\033[0m"
echo -e "\033[32mDo you want to use this commit message? [Y/n]\033[0m"

read answer

# 如果用户回答'Y'或者'y'，那么执行git commit命令
if [ "$answer" == "Y" ] || [ "$answer" == "y" ] || [ -z "$answer" ]; then
    git commit -a -F $file_path
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Commit successful.${RESET}"
    else
      echo -e "${RED}Commit failed.${RESET}"
    fi
else
    echo -e "\033[31mCommit cancelled.\033[0m"
fi


# 删除临时文件
rm $file_path
