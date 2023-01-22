package unittest

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestDummy(t *testing.T) {
	plan := readJsonPlan(t, "terraform/plans/default.tfplan.json")
	for _, change := range plan.ResourceChanges {
		fmt.Printf("%#v\n", change.Change.After)
	}

	fmt.Printf("\n\n%#v\n", plan.ResourceChanges[1].Change.After)

	assert.True(t, true)
}
