// Package services defines the application-specific configuration for baz
// This file instantiates the shared application template with baz-specific settings
package apps

import core "example.com/cue-example/services/core"

// baz application configuration
// Uses the #App template with baz-specific customizations
baz: core.#App & {
	// Set the application name
	appName: "baz"

	// Add app-specific environment variables that will be present in ALL environments
	// Environments can add additional env vars via their appConfig.deployment.additionalEnv
	// The lists will be concatenated together
	appConfig: deployment: additionalEnv: [
		{
			name:  "BAZ_FEATURE_FLAG"
			value: "enabled"
		},
		{
			name:  "BAZ_API_VERSION"
			value: "v2"
		},
	]
}
