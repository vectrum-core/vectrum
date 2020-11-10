#!/usr/bin/env bats
load helpers/general

SCRIPT_LOCATION="scripts/uninstall.sh"
TEST_LABEL="[vectrum_uninstall]"

mkdir -p $SRC_DIR
mkdir -p $OPT_DIR
mkdir -p $VAR_DIR
mkdir -p $BIN_DIR
mkdir -p $VAR_DIR/log
mkdir -p $ETC_DIR
mkdir -p $LIB_DIR
mkdir -p $MONGODB_LOG_DIR
mkdir -p $MONGODB_DATA_DIR

# A helper function is available to show output and status: `debug`

@test "${TEST_LABEL} > Testing user prompts" {
  ## No y or no warning and re-prompt
  run bash -c "echo -e \"\nx\nx\nx\" | ./$SCRIPT_LOCATION"
  ( [[ "${lines[${#lines[@]}-1]}" == "Please type 'y' for yes or 'n' for no." ]] && [[ "${lines[${#lines[@]}-2]}" == "Please type 'y' for yes or 'n' for no." ]] ) || exit
  ## All yes pass
  run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION"
  [[ $output =~ " - VECTRUM Removal Complete" ]] || exit
  ## First no shows "Cancelled..."
  run bash -c "echo \"n\" | ./$SCRIPT_LOCATION"
  [[ "${output##*$'\n'}" =~ "Cancelled VECTRUM Removal!" ]] || exit
  ## What would you like to do?"
  run bash -c "echo \"\" | ./$SCRIPT_LOCATION"
  [[ "${output##*$'\n'}" =~ "What would you like to do?" ]] || exit
}

@test "${TEST_LABEL} > Testing executions" {
  run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION"
  [[ "${output[*]}" =~ "Executing: rm -rf" ]] || exit
  if [[ $ARCH == "Darwin" ]]; then
    [[ "${output}" =~ "Executing: brew uninstall cmake --force" ]] || exit
  fi
}

@test "${TEST_LABEL} > Usage is visible with right interaction" {
  run ./$SCRIPT_LOCATION -h
  [[ $output =~ "Usage:" ]] || exit
}

@test "${TEST_LABEL} > -y" {
  run ./$SCRIPT_LOCATION -y
  [[ $output =~ " - VECTRUM Removal Complete" ]] || exit
}

@test "${TEST_LABEL} > -i" {
  run ./$SCRIPT_LOCATION -y -i vectrumtest
  [[ $output =~ .*/vectrumtest ]] || exit
  ([[ ! $output =~ "Library/Application\ Support/vectrum" ]] && [[ ! $output =~ ".local/share/vectrum" ]]) || exit
  [[ ! $output =~ "VECTRUM Removal Complete" ]] || exit
}

@test "${TEST_LABEL} > -f" {
  run bash -c "printf \"y\n%.0s\" {1..100} | ./$SCRIPT_LOCATION -f"
  ([[ "${output[*]}" =~ "Library/Application\ Support/vectrum" ]] && [[ "${output[*]}" =~ ".local/share/vectrum" ]]) && exit
  [[ $output =~ "VECTRUM Removal Complete" ]] || exit
}

rm -rf $SRC_DIR
rm -rf $OPT_DIR
rm -rf $VAR_DIR
rm -rf $BIN_DIR
rm -rf $VAR_DIR/log
rm -rf $ETC_DIR
rm -rf $LIB_DIR
rm -rf $MONGODB_LOG_DIR
rm -rf $MONGODB_DATA_DIR