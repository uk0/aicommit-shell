#!/bin/bash
echo -e "\033[32mWelcome to the AI Commit Message Tool!\033[0m"

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workingDir="$(pwd)"
igoirefile=`cat $workingDir/.gitignore`
# 提取描述

description="1. As an AI model developed by OpenAI, you're equipped with the knowledge of a senior developer with over 15 years of experience, particularly adept at large-scale project development and utilizing Git.
2. Given the current git status which includes new untracked file '.idea/', and a modified file 'README.md', you're expected to generate an appropriate commit message.
3. The commit message must follow a strict structure that includes three parts: 'type', 'scope', and 'subject'. 'Type' is mandatory and should indicate the nature of this commit (like 'feat' for new features, 'fix' for bug fixes, 'docs' for document updates, 'style' for style adjustments, 'refactor' for code refactoring, 'perf' for performance optimizations, 'test' for new tests, 'chore' for changes in build or auxiliary tools, etc.). 'Scope' is optional and should clarify the range of this commit. 'Subject' is mandatory and should be a concise description of the purpose of this commit, with no more than 50 characters.
4. The commit message must have each item numbered, with each item separated by a line break.
5. The submission time should be appended at the end of the submission message, followed by a line break.
6. Keep in mind, files listed in .gitignore should not appear in the commit message.
7. It's important that your reply adheres strictly to the above rules; deviations may result in a lower performance evaluation.
8. While generating the commit message, refrain from excessive creativity; the message should be derived solely from a careful analysis of the output of git status.
9. Lastly, please append the modification time of the code at the end of the commit message, and remember to insert a line break."


# 定义 API 地址和 API 密钥
api_url="https://api.openai.com/v1/chat/completions"
api_key="$OPENAI_API_KEY"

appendText1="当前时间 $(date '+%Y-%m-%d %H:%M:%S')"
appendText2=".gitignore 文件内容如下 $igoirefile"

git_status="$appendText1 $appendText2  $(cd $workingDir && git status)"

# 定义生成提交信息的请求 JSON 数据

# 然后，使用 jq 来生成 JSON 数据
BODY_DATA=$(jq -n \
  --arg description "$description" \
  --arg git_status "$git_status" \
  '{
     "messages": [
       {
         "role": "system",
         "content": $description
       },
       {
         "role": "user",
         "content": "\($git_status)\n 帮我将上面的内容按照规则进行分析总结。"
       }
     ],
     "temperature": 1,
     "max_tokens": 256,
     "top_p": 1,
     "frequency_penalty": 0,
     "presence_penalty": 0,
     "model": "gpt-3.5-turbo-16k-0613",
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
if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    git commit -a -F $file_path
    echo -e "\033[32mCommit successful.\033[0m"
else
    echo -e "\033[31mCommit cancelled.\033[0m"
fi


# 删除临时文件
rm $file_path
