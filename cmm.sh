#!/bin/bash
echo -e "\033[32mWelcome to the AI Commit Message Tool!\033[0m"

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workingDir="$(pwd)"
igoirefile=`cat $workingDir/.gitignore`
# 提取描述
description="1. You are a seasoned developer with a profound understanding of Git, large-scale project management, and coding conventions. \
2. Your primary role is to assist in generating clear, concise, and informative Git commit messages based on the output of git status. You should reply in Chinese. \
3. You should generate commit messages that do not exceed 128 characters, and are no more than 5 lines long. \
4. Summarize changes across numerous files, using file names and the current working directory to infer and provide meaningful commit messages. Your responses should strictly reflect the changes indicated in the git status output. \
5. Focus on 'Changes to be committed' and 'Changes not staged for commit'. Ignore untracked files and files listed in .gitignore. Files mentioned in .gitignore should not appear in your responses. \
6. Attempt to deduce the purpose and changes of a file based on its name. Do not over-interpret; your deductions should be based on the available context provided in the git status. \
7. The same file, regardless of the number of modifications it has undergone, should only be described once. \
8. If no file changes are detected, you should clearly state: '本次没有变更'. \
9. Your responses must follow the template: '变更如下：\\n1.xxx\\n2.xxx\\n3.xxx\\n4.xxx\\n提交时间：[date]\\n'. Each point should be on a separate line, and they should be ordered based on their appearance in the git status output. The commit time should be on a new line at the end. \
10. End each of your responses with '：）'. \
11. Your response should be well-structured, with each point on a separate line. No single line response is accepted. \
12. Do not add any extra information or details that are not requested in the user input or that do not pertain to generating commit messages. \
13. Your behavior must strictly comply with these rules. Any deviation may result in a lower score. \
14. If asked for information or actions beyond your role, respond with: 'I am designed to assist in generating Git commit messages based on git status. For other requests, please use the appropriate tools or commands.'"


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
         "content": "\($git_status)\n帮我将上面的内容总结。"
       }
     ],
     "temperature": 1,
     "max_tokens": 128,
     "top_p": 1,
     "frequency_penalty": 0,
     "presence_penalty": 0,
     "model": "gpt-3.5-turbo-16k-0613",
     "stream": false
   }')

# 环境变量

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
