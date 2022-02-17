package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// An example of how to test the simple Terraform module in examples/terraform-basic-example using Terratest.
func TestTerraformBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
		VarFiles: []string{"examples/basic/fixtures.tfvars"},
		NoColor: true,
		Upgrade: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

}