// Package services defines the application-specific configuration for baz
// This file instantiates the shared application template with baz-specific settings
package services

// baz application configuration
// Uses the #AppBase template from base.cue with baz-specific customizations
baz: #AppBase & {
	// Set the application name
	appName: "baz"

	// Use default namespace pattern: "baz-namespace"
	// Can be overridden by environments via appConfig.namespace

	// Resources exported for this app: deployment and service
	// This is the default from #AppBase, explicitly shown here for clarity
	resources_list: ["deployment", "service"]

	// Add app-specific environment variables
	// These will be present in ALL environments (dev, stage, prod)
	appConfig: additionalEnv: [
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
