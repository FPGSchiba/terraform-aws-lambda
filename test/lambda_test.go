package test

import (
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestTerraformLambda(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./terraform",
		Vars: map[string]interface{}{
			"random_prefix": random.UniqueId(),
		},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	output := terraform.Output(t, terraformOptions, "lambda_result")
	assert.Equal(t, "\"success\"", output)
}
func TestTerraformLambdaDestroy(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./terraform",
		Vars: map[string]interface{}{
			"random_prefix": random.UniqueId(),
		},
	})
	terraform.InitAndApply(t, terraformOptions)
	terraform.Destroy(t, terraformOptions)
}
func TestTerraformLambdaInvalidConfig(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./terraform",
		Vars: map[string]interface{}{
			"runtime":       "bli_blah_blub",
			"random_prefix": random.UniqueId(),
		},
	})
	defer terraform.Destroy(t, terraformOptions)
	// Expect an error during apply
	_, err := terraform.InitAndApplyE(t, terraformOptions)
	assert.Error(t, err)
}
