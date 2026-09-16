#!/usr/bin/env bash
# abc pdr's trace violates a_onehot at step 3 and a_latency at step 4; smtbmc once checked step 4 only.

set -e

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

${YOSYS} -q -p "read_verilog -formal -sv smtbmc_witness_skip.sv; prep; async2sync; formalff -clk2ff -ff2anyinit; opt -full;
	write_smt2 $tmp/model.smt2"

# Solver responses recorded with yices for the replay below.
cat > "$tmp/solver.txt" <<'EOT'
unsat
unsat
unsat
sat
(((|arbiter_2_a| s3) false))
(((|arbiter_2_a 0| s3) true))
(((|arbiter_2_a 1| s3) false))
EOT

${YOSYS_SMTBMC} -s dummy --dummy "$tmp/solver.txt" --noprogress --yw smtbmc_witness_skip.yw "$tmp/model.smt2" > "$tmp/smtbmc.log" 2>&1 || true
cat "$tmp/smtbmc.log"
grep -q "Checking assertions in step 3\.\." "$tmp/smtbmc.log"
grep -q "Assert failed in arbiter_2: a_onehot" "$tmp/smtbmc.log"
! grep -q "Assert failed in arbiter_2: a_latency" "$tmp/smtbmc.log"
grep -q "Status: FAILED" "$tmp/smtbmc.log"
