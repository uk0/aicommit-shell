#!/bin/bash
echo -e "\033[32mWelcome to the AI Commit Message Tool!\033[0m"

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workingDir="$(pwd)"
igoirefile=`cat $workingDir/.gitignore`
# 提取描述

#description="1. As an AI model developed by OpenAI, you're equipped with the knowledge of a senior developer. Your task is to generate appropriate Git commit messages based on the given git status.
#            2. The commit message should strictly follow this format: '<type>(<scope>): <subject>', a blank line, '<body>', another blank line, and then '<footer>'. Each commit message should end with the current time.
#            3. The commit message should derive solely from a careful analysis of the output of git status. Do not incorporate any files listed in .gitignore in the commit message.
#            4. For example, if the current git status includes a new untracked file named '.idea' and a modified file named 'README.md', generate a commit message based on this information.
#            5. The 'type' field is mandatory and should indicate the nature of this commit ('feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore' etc.). 'Scope' is optional and should clarify the range of this commit. 'Subject' is mandatory and should be a concise description of the purpose of this commit, not exceeding 50 characters.
#            6. Each item of the commit message must be numbered, and items must be separated by line breaks.
#            7. Your generated commit message should strictly adhere to the above rules. Deviations may result in lower performance evaluation.
#            8. Remember, you are to provide only the final result - the commit message, based on your analysis. No additional information or process descriptions should be included. Furthermore, ensure the overall length of the commit message does not exceed 256 characters."


description=`cat prompt.txt`

# 定义 API 地址和 API 密钥
api_url="https://api.openai.com/v1/chat/completions"
api_key="$OPENAI_API_KEY"

appendText1="当前时间  $(date '+%Y-%m-%d %H:%M:%S')"

git_status="$appendText1  $(cd $workingDir && git status)"

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
         "content": "\($git_status)\n "
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
