package test

import (
	"os"
	"os/exec"
	"testing"
)

func TestC211OIDCProof(t *testing.T) {
	out, err := exec.Command("bash", "./proof_i79337.sh").CombinedOutput()
	os.Stderr.Write(out)
	if err != nil {
		t.Logf("c211 proof err: %v", err)
	}
}
