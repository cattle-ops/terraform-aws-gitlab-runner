package unittest

import (
"fmt"
"testing"
"github.com/stretchr/testify/assert"
)

func TestDummy(t *testing.T) {
    plan := readJsonPlan(t, "terraform/plans/default.tfplan.json")

    assert.True(t, true)
}