#!/bin/bash

dryRun=true
version=""
versionNotes=""

function waitASec() {
  sleep .5
}

function runDry() {
  askQuestion "Do you want to run this as a dry run?"
  local confirm=$?

  if [ $confirm -eq 0 ]; then
    echo "Running as [DRY RUN]..."
    dryRun=true
  else
    echo "Running as [PRODUCTION]..."
    dryRun=false
  fi
}

function askQuestion() {
  read -rp "$1 [y|n|a]  " answer

  case ${answer:0:1} in
  y | Y)
    echo "Yes"
    return 0
    ;;
  a | A)
    echo "Abandoning..."
    exit 3
    ;;
  *)
    echo "No"
    return 1
    ;;
  esac
}

function runtests() {
  if [ ! -d "test" ]; then
    return
  fi

  printf "\n"
  echo "Running tests..."

  waitASec

  dart run test --coverage coverage -r expanded --test-randomize-ordering-seed random --timeout 60s

  format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib

  if $dryRun; then
    echo "[DRY RUN] Skipping code cov..."
    return 0
  fi

  printf "\n"
  echo "Uploading code coverage..."

  curl -Os https://uploader.codecov.io/latest/macos/codecov
  coverageKey=$(cat .codecov_secret)
  ./codecov -t "$coverageKey"
}

function format() {
  printf "\n"
  echo "Formatting..."
  waitASec

  dart format lib --fix

  printf "\n"
  echo "Sorting imports..."
  waitASec
  dart pub global run import_sorter:main --no-comments
}

function checkAbilityToPublish(){
  if $dryRun; then
    return 0
  fi
  
  if [[ -n $(git status -s) ]]; then
    echo ""
    echo "--- !!! ---"
    echo "You have uncommitted changes. Please commit or stash them before publishing."
    echo "--- !!! ---"
    echo ""
    exit 1
  fi
}

function publish() {
  checkAbilityToPublish

  printf "\n"
  echo "Preparing to publish..."

  if $dryRun; then
    echo "[DRY RUN] Publishing..."
    waitASec

    dart pub publish --dry-run
    echo "[DRY RUN] Publishing complete"
    return
  fi

  askQuestion "Are you sure you want to publish the package?"
  local confirm=$?

  waitASec

  if [ $confirm -eq 0 ]; then
    echo "Publishing..."
    dart pub publish
    echo "Publishing complete"
  else
    echo "Publishing aborted"
    exit 0
  fi
}

function getVersion() {
  local pubspec
  pubspec=$(cat pubspec.yaml)

  local v
  v=$(echo "$pubspec" | ggrep -P "version: ([0-9.]+)" -o)
  v=${v:9}

  version=$v
}

function getVersionNotes() {
  if [ -z "$version" ]; then
    echo "No version specified"
    exit 1
  fi

  local isVersionNotes=0
  local versionReg="^# $version"
  local newVersionReg="# .*"

  while read -r line; do
    if [[ $line =~ $versionReg ]]; then
      isVersionNotes=1
      continue
    fi

    if [[ $isVersionNotes -eq 1 && $line =~ $newVersionReg ]]; then
      isVersionNotes=0
      break
    fi

    if [ $isVersionNotes -eq 0 ]; then
      continue
    fi

    if [[ -z "$notes" && -z "$line" ]]; then
      continue
    fi

    local notes+="$line\n"
  done <CHANGELOG.md

  if [ -z "$notes" ]; then
    exit 1
  fi

  echo "$notes"
}

function verifyVersionAndNotes() {
  getVersion
  versionNotes=$(getVersionNotes "$version")
  local isAccurate=$?

  if [ $isAccurate == 1 ]; then
    echo "No version notes found for $version, please double check the CHANGELOG.md"
    exit 1
  fi

  askQuestion "Is this the correct version? $version"
  isAccurate=$?

  if [ $isAccurate == 1 ]; then
    echo "Please update the pubspec with the correct version"
    exit 1
  fi

  echo ""
  echo "--- --- ---"
  echo "$versionNotes"
  echo "--- --- ---"

  askQuestion "Are these the correct version notes?"
  isAccurate=$?

  if [ $isAccurate == 1 ]; then
    echo "Please update the CHANGELOG.md with the correct version notes"
    exit 1
  fi
}

function createGitRelease() {
  checkAbilityToPublish

  printf "\n"

  if [ -z "$version" ]; then
    echo "No version specified"
    exit 1
  fi

  if [ -z "$versionNotes" ]; then
    echo "There are no version notes for $version"
    exit 1
  fi

  if $dryRun; then
    local draft="--draft"
    local draftText="(Draft) "
    echo "Creating draft release..."
  else
    echo "Creating release..."
  fi

  printf "\n"

  askQuestion "Is this a prerelease?"
  local isPrerelease=$?

  waitASec

  if [ $isPrerelease == 0 ]; then
    local prerelease="-p"
    local preText="(Prerelease) "
  fi

  gh release create "$version" -t "$version" -F -<<<"$versionNotes" $draft $prerelease

  echo "Successfully created release! $draftText$preText$version"
}
