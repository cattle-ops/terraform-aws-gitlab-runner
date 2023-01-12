package unittest

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestDummy(t *testing.T) {
	plan := readJsonPlan(t, "terraform/plans/default.tfplan.json")

	assert.True(t, true)
}
