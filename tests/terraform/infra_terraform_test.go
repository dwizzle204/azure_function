package terraformtests

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestInfraInitAndValidate(t *testing.T) {
	t.Parallel()

	tempInfraDir := prepareInfraForLocalValidation(t)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempInfraDir,
		EnvVars: map[string]string{
			"TF_IN_AUTOMATION": "1",
		},
	})

	terraform.InitAndValidate(t, terraformOptions)
}

func TestInfraContractOutputsAndValidationRules(t *testing.T) {
	t.Parallel()

	repoRoot := repoRoot(t)
	configDir := terraformConfigDir(t)
	outputsPath := filepath.Join(repoRoot, configDir, "outputs.tf")
	variablesPath := filepath.Join(repoRoot, configDir, "variables.tf")

	outputsContent, err := os.ReadFile(outputsPath)
	require.NoError(t, err)

	variablesContent, err := os.ReadFile(variablesPath)
	require.NoError(t, err)

	outputsText := string(outputsContent)
	variablesText := string(variablesContent)

	for _, outputName := range []string{
		"function_app_name",
		"function_app_id",
		"function_app_default_hostname",
		"storage_account_name",
		"vnet_integration_enabled",
		"key_vault_name",
		"key_vault_uri",
	} {
		require.Contains(t, outputsText, "output \""+outputName+"\"", "missing terraform output %q", outputName)
	}

	for _, expectedValidation := range []string{
		"function_app_integration_subnet_id must be set when enable_vnet_integration=true.",
		"private_endpoint_subnet_id and storage_private_dns_zone_id must be set when enable_storage_private_endpoint=true.",
		"private_endpoint_subnet_id and function_app_private_dns_zone_id must be set when enable_function_app_private_endpoint=true.",
		"private_endpoint_subnet_id must be set when enable_key_vault=true and enable_key_vault_private_endpoint=true.",
	} {
		require.Contains(t, variablesText, expectedValidation)
	}
}

func prepareInfraForLocalValidation(t *testing.T) string {
	t.Helper()

	repoRoot := repoRoot(t)
	configDir := terraformConfigDir(t)
	sourceInfraDir := filepath.Join(repoRoot, configDir)
	tempDir := t.TempDir()
	destInfraDir := filepath.Join(tempDir, "infra")

	copyDir(t, sourceInfraDir, destInfraDir)
	sanitizeProvidersForLocalValidation(t, filepath.Join(destInfraDir, "providers.tf"))

	return destInfraDir
}

func repoRoot(t *testing.T) string {
	t.Helper()

	wd, err := os.Getwd()
	require.NoError(t, err)

	return filepath.Clean(filepath.Join(wd, "..", ".."))
}

func terraformConfigDir(t *testing.T) string {
	t.Helper()

	configDir := os.Getenv("TERRAFORM_CONFIG_DIRECTORY")
	if configDir == "" {
		return "infra"
	}

	return filepath.Clean(configDir)
}

func copyDir(t *testing.T, src, dst string) {
	t.Helper()

	entries, err := os.ReadDir(src)
	require.NoError(t, err)
	require.NoError(t, os.MkdirAll(dst, 0o755))

	for _, entry := range entries {
		name := entry.Name()
		if name == ".terraform" {
			continue
		}

		srcPath := filepath.Join(src, name)
		dstPath := filepath.Join(dst, name)

		if entry.IsDir() {
			copyDir(t, srcPath, dstPath)
			continue
		}

		contents, readErr := os.ReadFile(srcPath)
		require.NoError(t, readErr)
		require.NoError(t, os.WriteFile(dstPath, contents, 0o644))
	}
}

func sanitizeProvidersForLocalValidation(t *testing.T, providersPath string) {
	t.Helper()

	content, err := os.ReadFile(providersPath)
	require.NoError(t, err)

	lines := strings.Split(string(content), "\n")
	result := make([]string, 0, len(lines))

	skippingCloudBlock := false
	braceDepth := 0

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		if !skippingCloudBlock && strings.HasPrefix(trimmed, "cloud") && strings.Contains(trimmed, "{") {
			skippingCloudBlock = true
			braceDepth = strings.Count(line, "{") - strings.Count(line, "}")
			continue
		}

		if skippingCloudBlock {
			braceDepth += strings.Count(line, "{")
			braceDepth -= strings.Count(line, "}")
			if braceDepth <= 0 {
				skippingCloudBlock = false
			}
			continue
		}

		result = append(result, line)
	}

	require.NoError(t, os.WriteFile(providersPath, []byte(strings.Join(result, "\n")), 0o644))
}
