#!/usr/bin/env bats

setup() {
  # Create a mock profile environment in a temporary directory
  export RESTIC_OPS_PROFILE_ROOT="$BATS_TMPDIR/profiles"
  mkdir -p "$RESTIC_OPS_PROFILE_ROOT/test-profile"
  touch "$RESTIC_OPS_PROFILE_ROOT/test-profile/include.txt"
  touch "$RESTIC_OPS_PROFILE_ROOT/test-profile/exclude.txt"
  touch "$RESTIC_OPS_PROFILE_ROOT/test-profile/restic.env.gpg"
}

@test "selector.sh fails on missing profile" {
  run ./bin/selector.sh invalid-profile backup
  
  [ "$status" -eq 66 ]
  echo "$output" | grep -q "profile not found"
}

@test "selector.sh rejects invalid profile names" {
  run ./bin/selector.sh "../sneaky" backup
  
  [ "$status" -eq 64 ]
  echo "$output" | grep -q "invalid profile name"
}

@test "selector.sh fails if primitive script is missing" {
  run ./bin/selector.sh test-profile non-existent-operation
  
  [ "$status" -eq 64 ]
  echo "$output" | grep -q "unsupported operation"
}
