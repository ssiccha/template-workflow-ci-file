#!/usr/bin/env bash
if [ $# -ne 3 ]; then
    echo -n "Usage: create-action-pr.sh <CI_file_location> <repo_name>"
    echo " <repo_full_name>"
fi
CI_file_location=${1}
repo_name=${2}
repo_full_name=${3}
echo "Working on repository "${repo_name}
cd /home/sergio/projects/gap-actions
mkdir -p ___create-action-prs/
cd ___create-action-prs/
# Get the repo. If the gap-packages/package repo is itself a fork, then this
# command prompts for which repo should be the target of PRs etc.
gh repo fork ${repo_full_name} --clone --remote=false
cd ${repo_name}
git switch -c "ss/add-GitHub-actions-for-package-tests"
# Add the CI action yaml file
if [ ! -f .github/workflows/CI.yml ]; then
    mkdir -p .github/workflows
    cp ${CI_file_location} .github/workflows
    git add .github/workflows/CI.yml
    git commit -m "Add GitHub Action for continuous integration"
else
    echo "Actions CI file exists"
    exit 0
fi
# Remove .travis.yml if it exists
if [ -f .travis.yml ]; then
    git rm .travis.yml
    git commit -m "Remove .travis.yml"
else
    echo "No .travis.yml found."
fi
# The CI action badge
CI_badge_string='[![Build Status](https://github.com/gap-packages/'
CI_badge_string+=${repo_name}
CI_badge_string+='/workflows/CI/badge.svg?branch=master)](https://github.com/gap-packages/'
CI_badge_string+=${repo_name}
CI_badge_string+='/actions?query=workflow%3ACI+branch%3Amaster)'
if [ -f README.md ]; then
    # Add action badge if it does not exist already
    if [ -z "$(grep -F "${CI_badge_string}" README.md)" ]; then
        sed -i -e "1i ""${CI_badge_string}" README.md
        git add README.md
        git commit -m "Add CI action badge"
    else
        echo "Found CI action badge in README.md."
    fi
    # Remove travis badge if it exists
    if [ -n "$(grep 'Build Status.*travis-ci' README.md)" ]; then
        sed -i -e '/Build Status.*travis-ci/d' README.md
        git add README.md
        git commit -m "Remove travis action badge"
    else
        echo "No travis CI badge found in README.md."
    fi
else
    echo "No README.md found."
fi
git push --set-upstream origin ss/add-GitHub-actions-for-package-tests
export inspect_action_results_url="https://github.com/ssiccha/${repo_name}/actions"
body=$(cat <<HERE-DOC
This PR configures GitHub Actions to run the package tests. It was created by a script. You can view the results of the added GitHub action at:
${inspect_action_results_url}

HERE-DOC
)
body+=$(cat <<'HERE-DOC'

This PR contains four commits which do:
- adds a file `.github/workflows/CI.yml` which configures GitHub Actions to run the package tests,
- removes the `.travis.yml` file if it exists in the package,
- adds a CI action badge to the README.md, if it found none, and
- removes the travis CI badge from the README.md, if it finds one.

Since this PR is generated automatically, please double-check that the last three commits do not break anything. You may also have to specify values for the variables `GAP_PKGS_TO_BUILD` and `GAP_PKGS_TO_CLONE` in the `.github/workflows/CI.yml` file as described further below.

The added GitHub action `CI` contains a job `test`, which runs your package's tests using the same scripts as previously did Travis, namely those from
https://github.com/gap-system/pkg-ci-scripts
By default it tests your package with the following gap branches:
- master
- stable-4.11
- stable-4.10

The action `CI` also contains a job `manual`, which compiles your package's documentation with latex and uploads the resulting pdf as an artifact, which means that it can be downloaded once all jobs of the action completed.

If you need to compile packages to load your package, set the input `GAP_PKGS_TO_BUILD` for the action `gap-actions/setup-gap-for-packages@v1` to a space-separated list of packages as follows:
```
- uses: gap-actions/setup-gap-for-packages@v1
  with:
    GAPBRANCH: ${{ matrix.gap-branch }}
    GAP_PKGS_TO_BUILD: "<list-of-packages>"
```

If you need to clone the development version of packages set the input `GAP_PKGS_TO_CLONE` for the action `gap-actions/setup-gap-for-packages@v1` to a space-separated list of packages as follows:
```
- uses: gap-actions/setup-gap-for-packages@v1
  with:
    GAPBRANCH: ${{ matrix.gap-branch }}
    GAP_PKGS_TO_CLONE: "<list-of-packages>"
```

Notice that you may also have to set inputs for the action `gap-actions/setup-gap-for-packages@v1` in the job `manual`.

If you want to adjust which tests are run have a look at the [documentation of the job matrix](https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix).

HERE-DOC
)
body+=$(cat <<HERE-DOC
You can add changes to this PR by adding my fork as a remote, checking it out and then committing and pushing as follows:
\`\`\`
git remote add ssiccha https://github.com/ssiccha/${repo_name}
git checkout ss/add-GitHub-actions-for-package-tests
# Add and commit your changes
...
git push
\`\`\`

The custom gap actions which are used by the added action can be found at:
https://github.com/gap-actions
HERE-DOC
)
gh pr create --title "Add GitHub action for CI tests" --body "${body}"
# Clean up afterwards
cd ..
rm -rf ${repo_name}
