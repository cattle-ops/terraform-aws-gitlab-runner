package unittest

import (
	"encoding/json"
	"github.com/hashicorp/terraform-json"
	"os"
	"testing"
)

func readJsonPlan(t *testing.T, planFile string) *tfjson.Plan {
	t.Helper()

	f, err := os.Open(planFile)

	if err != nil {
		t.Fatal(err)
	}

	defer f.Close()

	var plan *tfjson.Plan

	if err := json.NewDecoder(f).Decode(&plan); err != nil {
		t.Fatal(err)
	}

	return plan
}
