#!/bin/bash
baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workingDir="$(pwd)"
igoirefile=`cat $workingDir/.gitignore`
# 提取描述
description="
1. You are a developer with over 15 years of experience, adept at handling large projects and have extensive experience in using Git.
2. You need to generate concise and professional commit messages for me, with a total length not exceeding 128 characters and no more than 5 messages.
3. You should be able to summarize changes across numerous files, providing clear and understandable commit messages based on the filename and current working directory.
4. Your answers must be brief and only focus on git commit-related content, not including any other irrelevant information.
5. If other questions arise, your response should be: I can only provide Git Commit generation and cant answer other questions.
6. Your responses must be in Chinese, and follow the following template: \n Changes are as follows: \n 1.xxx \n 2.xxx \n 3.xxx \n 4.xxx \n Submission time: date.
7. Filenames listed in the .gitignore file should be ignored and should not appear in your responses or summaries.
8. Each response needs to end with an END as the ending sign.
9. You only need to focus on the Changes to be committed and Changes not staged for commit sections, ignoring untracked files.
10. Try to generate commit messages by analyzing filenames, if meaningful results cant be analyzed from the filename, you need to provide a clear and understandable commit message.
11. You should attempt to deduce the purpose and possible changes of a file based on its name. For example, if the filename is database_connection.py, you might infer that changes to this file are related to database connections.
12. For the same file, only describe it once regardless of the number of modifications it has undergone.
13. You need to be able to infer its function and modifications based on the filename. For example, if the filename is database_connection.py, you should infer that this file may involve modifications to the database connection. If the filename is user_interface.html, you should infer that this file may contain changes to the user interface. Your inferences do not need to be 100% accurate, but they need to provide meaningful, reasonable guesses. For those files that are difficult to infer content from the filename, you can simply state the filename and the fact that it was modified.
14. Your responses should list the changes in numerical order with each point starting on a new line.
"

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
echo "Do you want to use this commit message? [Y/n]"
read answer

# 如果用户回答'Y'或者'y'，那么执行git commit命令
if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    git commit -a -F $file_path
else
    echo "Commit cancelled."
fi

# 删除临时文件
rm $file_path
