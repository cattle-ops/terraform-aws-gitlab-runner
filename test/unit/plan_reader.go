package unittest

import (
"encoding/json"
"io/ioutil"
"testing"
"github.com/hashicorp/terraform-json"
"github.com/stretchr/testify/require"
)

func readJsonPlan(t *testing.T, planFile string) *tfjson.Plan {
    t.Helper()

    planJson, err := ioutil.ReadFile(planFile)
    require.NoError(t, err)

    plan := tfjson.Plan{}
    err = json.Unmarshal(planJson, &plan)

    return &plan
}