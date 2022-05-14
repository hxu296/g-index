import pandas as pd
import requests
import json
import base64
from github import Github
from tqdm import tqdm

# using an access token
g = Github("access_token")

def get_committer_network(commits, commits_by_committer, allow_loose_connection=False):
    """
    Return the connection between committers
    Two committers are said to be connected if they've contributed to the same repository
    :param allow_loose_connection: False -> use full repo_name; True -> use short repo_name
    """
    # construct a hashmap from committer to number of commits
    commits_by_committer_dict = {}
    for _, row in commits_by_committer.iterrows():
        committer = (row["name"], row["institution"], row["email"])
        commits_by_committer_dict[committer] = row["committer_commit"]

    # construct a hashmap from repositories to committers (key: repo_name, value: set of committers)
    repos_committers = {}
    for _, row in commits.iterrows():
        committer = (row["name"], row["institution"], row["num_commits"], commits_by_committer_dict[(row["name"], row["institution"], row["email"])])
        repo_name = row["repo_name"].split("/")[1] if allow_loose_connection else row["repo_name"]
        if repo_name not in repos_committers:
            repos_committers[repo_name] = set()
        repos_committers[repo_name].add(committer)
    # construct network from committers to another committer
    network = []
    for _, row in commits.iterrows():
        committer = (row["name"], row["institution"], row["num_commits"], commits_by_committer_dict[(row["name"], row["institution"], row["email"])])
        repo_name = row["repo_name"].split("/")[1] if allow_loose_connection else row["repo_name"]
        for other_committer in repos_committers[repo_name]:
            if committer != other_committer and committer[2] > 10 and other_committer[2] > 10:
                network.append((committer[0], committer[1], committer[2], committer[3], other_committer[0], other_committer[1], other_committer[2], other_committer[3]))
    # remove duplicates
    network = list(set(network)) 
    print('dicovered {} connections'.format(len(network)))
    return network

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
    commits_by_committer = pd.read_csv("data/commits_by_committer.csv")
    network = get_committer_network(commits, commits_by_committer)
    # convert netowrk to a dataframe
    network_df = pd.DataFrame(network)
    # save network to disk
    network_df.to_csv("data/network.csv", index=False)

if __name__ == '__main__':
    test()
