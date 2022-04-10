import pandas as pd
import requests
import json
import base64
from github import Github
from tqdm import tqdm

# using an access token
g = Github("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")

def get_repos_info(repos_names):
    """
    Get repo information from the Github REST API
    """
    repos_info = {
        "query_success": [],
        "repo_name": [],
        "repo_description": [],
        "repo_created_at": [],
        "repo_updated_at": [],
        "repo_last_pushed_at": [],
        "language": [],
        "repo_stars": [],
        "homepage": [],
        "fork": [],
        "parent_repo_name": [],
        "parent_repo_stars": [],
        "topics": [],
    }
    for repo_name in tqdm(repos_names):
        repos_info["repo_name"].append(repo_name)
        try:
            repo = g.get_repo(repo_name)
            if repo.fork:
                repos_info["fork"].append(True)
                repos_info["parent_repo_name"].append(repo.parent.full_name)
                repos_info["parent_repo_stars"].append(repo.parent.stargazers_count)
                repos_info['repo_stars'].append(repo.stargazers_count)
            else:
                repos_info["fork"].append(False)
                repos_info["parent_repo_name"].append(None)
                repos_info["parent_repo_stars"].append(None)
                repos_info['repo_stars'].append(repo.stargazers_count)
            repos_info['repo_description'].append(repo.description)
            repos_info['repo_created_at'].append(str(repo.created_at))
            repos_info['repo_updated_at'].append(str(repo.updated_at))
            repos_info['repo_last_pushed_at'].append(str(repo.pushed_at))
            repos_info['language'].append(repo.language)
            repos_info['homepage'].append(repo.homepage)
            repos_info['query_success'].append(True)
            repos_info['topics'].append(repo.get_topics())
        except:
            repos_info['fork'].append(None)
            repos_info['parent_repo_name'].append(None)
            repos_info['parent_repo_stars'].append(None)
            repos_info['repo_stars'].append(None)
            repos_info['repo_description'].append(None)
            repos_info['repo_created_at'].append(None)
            repos_info['repo_updated_at'].append(None)
            repos_info['repo_last_pushed_at'].append(None)
            repos_info['language'].append(None)
            repos_info['homepage'].append(None)
            repos_info['query_success'].append(False)
            repos_info['topics'].append(None)
    return repos_info

def main():
    """
    Main function
    """
    # read commits from data/commits.csv
    commits = pd.read_csv("data/commits.csv")
    # gather repo_name into a set
    repos_full_names = set(commits["repo_name"][:10])
    repos_info = get_repos_info(repos_full_names)
    # save repos_info to disk
    print({k:len(v) for k,v in repos_info.items()})
    repos_info_df = pd.DataFrame(repos_info)
    repos_info_df.to_csv("data/repos_info.csv", index=False)

def test():
    # read commits from data/commits.csv
    commits = pd.read_csv("data/commits.csv")
    # gather repo_name into a set
    repos_full_names = set(commits["repo_name"])
    # exclude user name from repos_name
    repos_short_names = set([repo_name.split("/")[1] for repo_name in repos_full_names])
    print(len(repos_full_names), len(repos_short_names))

if __name__ == '__main__':
    main()