#!/bin/bash
GITHUB_TOKEN="$1"
if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "ERROR: GitHub token required"
    exit 1
fi

# Use curl to fetch GitHub repositories
RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user/repos?per_page=100&sort=updated")

# Check if authentication failed
if echo "${RESPONSE}" | grep -q '"message": "Bad credentials"'; then
    echo "ERROR: Invalid GitHub token"
    exit 1
fi

echo "GITHUB_REPOS_BEGIN"

# Parse JSON response and output in expected format
echo "${RESPONSE}" | python3 -c "
import sys, json
try:
    repos = json.load(sys.stdin)
    for repo in repos:
        print('GITHUB_REPO_NAME:' + repo['name'])
        print('GITHUB_REPO_FULLNAME:' + repo['full_name'])
        print('GITHUB_REPO_URL:' + repo['clone_url'])
        print('GITHUB_REPO_DESC:' + repo.get('description', ''))
        print('GITHUB_REPO_PRIVATE:' + str(repo['private']).lower())
        print('GITHUB_REPO_SEPARATOR')
except Exception as e:
    print(f'ERROR: Failed to parse response: {e}', file=sys.stderr)
    sys.exit(1)
"

echo "GITHUB_REPOS_END"
exit 0
