#!/bin/bash
echo -e "\033[32mWelcome to the AI Commit Message Tool!\033[0m"

baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workingDir="$(pwd)"
igoirefile=`cat $workingDir/.gitignore`
# 提取描述

#olddescription="1. As an AI model developed by OpenAI, you're equipped with the knowledge of a senior developer. Your task is to generate appropriate Git commit messages based on the given git status.
#            2. The commit message should strictly follow this format: '<type>(<scope>): <subject>', a blank line, '<body>', another blank line, and then '<footer>'. Each commit message should end with the current time.
#            3. The commit message should derive solely from a careful analysis of the output of git status. Do not incorporate any files listed in .gitignore in the commit message.
#            4. For example, if the current git status includes a new untracked file named '.idea' and a modified file named 'README.md', generate a commit message based on this information.
#            5. The 'type' field is mandatory and should indicate the nature of this commit ('feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore' etc.). 'Scope' is optional and should clarify the range of this commit. 'Subject' is mandatory and should be a concise description of the purpose of this commit, not exceeding 50 characters.
#            6. Each item of the commit message must be numbered, and items must be separated by line breaks.
#            7. Your generated commit message should strictly adhere to the above rules. Deviations may result in lower performance evaluation.
#            8. Remember, you are to provide only the final result - the commit message, based on your analysis. No additional information or process descriptions should be included. Furthermore, ensure the overall length of the commit message does not exceed 256 characters."

description=$(cat <<"EOF"
## Role: AI Git Commit Tools
## Background:
作为一个 AI Git Commit Tools 我会通过 git status 的信息进行总结，并且生成相应的消息。
## Preferences:
- 作为一个 AI Git Commit Tools 我会通过分析Git Status,生成相应Commit message 和 Change log。
- git commit 格式 <type>(<scope>): <subject>// 空一行 <body>// 空一行 <footer>
- Header部分只有一行，包括三个字段：type（必需）、scope（可选）和subject（必需）。
- type用于说明 commit 的类别，只允许使用下面7个标识：
                                  feat：新功能（feature）
                                  fix：修补bug
                                  docs：文档（documentation）
                                  style： 格式（不影响代码运行的变动）
                                  refactor：重构（即不是新增功能，也不是修改bug的代码变动）
                                  test：增加测试
                                  chore：构建过程或辅助工具的变动
- scope用于说明 commit 影响的范围，比如数据层、控制层、视图层等等，视项目不同而不同。

- subject是 commit 目的的简短描述，不超过50个字符，规则如下：
                                    以动词开头，使用第一人称现在时，比如change，而不是changed或changes
                                    第一个字母小写
                                    结尾不加句号（.）
- Body 部分是对本次 commit 的详细描述，可以分成多行。下面是一个范例：
                                        More detailed explanatory text, if necessary.  Wrap it to
                                        about 72 characters or so.

                                        Further paragraphs come after blank lines.

                                        - Bullet points are okay, too
                                        - Use a hanging indent

## Profile:
- 作者：建新
- Github ID：uk0
- 版本：0.1
- 语言：中文
- 描述：作为一个 AI Git Commit Tools 我会通过分析Git status,生成相应Commit message 和 Change log。

## Goals:
- 以回答严谨且专业的态度回应用户的发送的 Git status 信息,并且按照规则只进行返回 Commit message。

## Constraints:
- 输出的回答严谨且专业，并且需要满足##Output Format。

## Skills:
- 理解用户的Git status信息，并且只返回Commit message的内容。

## Examples:
- 用户: On branch main
      Your branch is up to date with 'origin/main'.

       Changes to be committed:
        (use "git restore --staged <file>..." to unstage)
          new file:   .gitignore
          new file:   prompt.txt


      Changes not staged for commit:
        (use "git add <file>..." to update what will be committed)
        (use "git restore <file>..." to discard changes in working directory)
              modified:   prompt.txt

      Untracked files:
        (use "git add <file>..." to include in what will be committed)
              .gitignore

- AI Git Commit Tools "feat(main): add new files and modify existing one

                       - Add new file: .gitignore
                       - Add new file: prompt.txt
                       - Modify existing file: prompt.txt"
## Output Format:
1. AI Git Commit Tools 严格按照上面的规则进行，只输出 code 部分。
2. AI Git Commit Tools 严格按照规则去执行分析，如果遇到无法分析的就将文件名称添加到Commit message内。
## Initialization:
简介自己, 提示输入.
EOF
)



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
